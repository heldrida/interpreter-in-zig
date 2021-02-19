const print = @import("std").debug.print;
const expect = @import("std").testing.expect;
const std = @import("std");
const token = @import("token.zig");

// Types
const Token = token.Token;
const TokenMap = token.TokenMap;

const Lexer = struct {
  input: []const u8,
  // current position in input (points to current char)
  position: u8,
  // current reading position in input (after current char)
  readPosition: u8,
  // current char under examination
  ch: TokenMap,
  // current literal
  literal: []const u8,
  
  // Checks if we reached end of input
  // if so sets to 0 (ASCII code for "NUL" char)
  // otherwise, sets `l.ch` to the next char
  fn readChar(self: *Lexer) Token {
    if (self.readPosition >= self.input.len) {
      self.ch = TokenMap.nul;
      self.literal = &[_]u8 { @enumToInt(self.ch) };
    } else if (isLetter(self.input[self.readPosition])) {
      var i: u8 = self.readPosition;

      while (i < self.input[self.readPosition..].len): (i += 1) {
        if (!isLetter(self.input[i])) {
          self.position = self.readPosition;
          self.readPosition = i;
          break;
        }
      }
      
      self.literal = self.input[self.position..self.readPosition];

      self.ch = literalToChar(self.literal);
    } else {
      self.ch = @intToEnum(TokenMap, self.input[self.readPosition]);
      self.literal = &[_]u8 { @enumToInt(self.ch) };
      self.position = self.readPosition;
      self.readPosition += 1;
    }

    return Token {
      .type = self.ch,
      .literal = self.literal
    };
  }

  fn isLetter(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'B');
  }

  fn nextToken(self: *Lexer) Token {
    const tk: Token = self.readChar();
    return tk;
  }

  fn literalToChar(literal: []const u8) TokenMap {
    var ch: TokenMap = undefined;

    if (std.mem.eql(u8, literal, "let")) {
      ch = TokenMap.let;
    } else {
      ch = @intToEnum(TokenMap, literal[0]);
    }

    return ch;
  }

  fn init(self: *Lexer, input: []const u8) void {
    self.input = input;
    self.position = 0;
    self.readPosition = 0;
    self.ch = @intToEnum(TokenMap, self.input[self.position]);    
  }

  fn create(allocator: *std.mem.Allocator, input: []const u8) !*Lexer {
    var l = try allocator.create(Lexer);

    // Initialisation
    l.init(input);

    return l;
  }
};

test "Verifies token types\n" {
  const input: []const u8 = "=+let(){},;";

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);

  const expectedType = struct {
      expectedType: TokenMap,
      expectedLiteral: []const u8
  };
  const testCases = [_]expectedType {
    .{
      .expectedType = TokenMap.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = TokenMap.plus,
      .expectedLiteral = "+"
    },
    .{
      .expectedType = TokenMap.let,
      .expectedLiteral = "let"
    },
    .{
      .expectedType = TokenMap.lparen,
      .expectedLiteral = "("
    },
    .{
      .expectedType = TokenMap.rparen,
      .expectedLiteral = ")"
    },
    .{
      .expectedType = TokenMap.lbrace,
      .expectedLiteral = "{"
    },
    .{
      .expectedType = TokenMap.rbrace,
      .expectedLiteral = "}"
    },
    .{
      .expectedType = TokenMap.comma,
      .expectedLiteral = ","
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap.nul,
      .expectedLiteral = ""
    }
  };

  for (testCases) |field| {
    const tok = l.nextToken();

    expect(tok.type == field.expectedType);
  }
}