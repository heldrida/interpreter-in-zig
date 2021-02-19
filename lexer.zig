const print = @import("std").debug.print;
const expect = @import("std").testing.expect;
const std = @import("std");
const token = @import("token.zig");

// Types
const Token = token.Token;
const TokenMap = token.TokenMap;
const WordRange = struct {
  start: u8,
  end: u8
};

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
      // Update character (set Nul)
      self.ch = TokenMap.nul;

      // Update literal
      self.literal = &[_]u8 { @enumToInt(self.ch) };
    } else if (isLetter(self.input[self.readPosition])) {
      // Find the word range
      const wr = self.getWordRange(self.readPosition);

      // Update positions      
      self.updatePosition(wr);

      // Update literal
      self.literal = self.input[wr.start..wr.end];

      // Update character
      self.ch = literalToChar(self.literal);
    } else {
      // Update character
      self.ch = @intToEnum(TokenMap, self.input[self.readPosition]);

      // Update literal
      self.literal = &[_]u8 { @enumToInt(self.ch) };

      // Update positions
      self.position = self.readPosition;
      self.readPosition += 1;
    }

    return Token {
      .type = self.ch,
      .literal = self.literal
    };
  }
  
  fn getWordRange(self: *Lexer, startPos: u8) WordRange {
    var i: u8 = startPos;

    while (i < startPos + self.input[startPos..].len): (i += 1) {
      if (!isLetter(self.input[i])) {
        return WordRange {
          .start = startPos,
          .end = i
        };
      }
    }

    return WordRange {
      .start = startPos,
      .end = 0
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

  fn updatePosition(self: *Lexer, wr: WordRange) void {
    self.position = wr.start;
    self.readPosition = wr.end;
  }

  fn init(self: *Lexer, input: []const u8) void {
    self.input = input;
    self.position = 0;
    self.readPosition = 0;
  }

  fn create(allocator: *std.mem.Allocator, input: []const u8) !*Lexer {
    var l = try allocator.create(Lexer);

    // Initialisation
    l.init(input);

    return l;
  }
};

test "Gets correct word range\n" {
  const input: []const u8 = "let{let!";

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);
  
  const wrFirst = l.getWordRange(0);
  const wrSecond = l.getWordRange(4);

  expect(wrFirst.start == 0 and wrFirst.end == 3);
  expect(wrSecond.start == 4 and wrSecond.end == 7);
}

test "Verifies token types\n" {
  const input: []const u8 = "let=+let(){},;";

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
      .expectedType = TokenMap.let,
      .expectedLiteral = "let"
    },
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
    // Get next token
    const tok = l.nextToken();

    // Assertion
    expect(tok.type == field.expectedType);
  }
}