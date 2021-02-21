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
  // allocator
  allocator: *std.mem.Allocator,
  // input
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
      // Update character (set EOF)
      self.ch = TokenMap.eof;

      // Update literal
      self.literal = "";
    } else if (isLetter(self.input[self.readPosition])) {
      // Find the word range
      const wr = self.getWordRange(self.readPosition);

      // Update positions      
      self.updatePosition(wr);

      // Update literal
      self.literal = self.input[wr.start..wr.end];

      // Update character
      self.ch = self.literalToChar(self.literal) catch TokenMap.nul;
    } else if (isDigit(self.input[self.readPosition])) {
      // Update character
      self.ch = TokenMap.int;

      // Update literal
      self.literal = self.input[self.readPosition..self.readPosition+1];

      // Update positions
      self.position = self.readPosition;
      self.readPosition += 1;
    } else if (isWhiteSpace(self.input[self.readPosition])) {
      // Update positions
      self.position = self.readPosition;
      self.readPosition += 1;

      // Skip to next
      return self.readChar();
    } else {
      // Update character
      self.ch = @intToEnum(TokenMap, self.input[self.readPosition]);

      // Update literal
      self.literal = self.input[self.readPosition..self.readPosition+1];

      // Update positions
      self.position = self.readPosition;
      self.readPosition += 1;
    }

    const tk = Token {
      .type = self.ch,
      .literal = self.literal
    };

    return tk;
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

  fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
  }

  fn isWhiteSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r';
  }

  fn nextToken(self: *Lexer) Token {
    const tk: Token = self.readChar();
    return tk;
  }

  fn literalToChar(self: *Lexer, literal: []const u8) !TokenMap {
    var ch: TokenMap = undefined;

    // Some keywords might clash with Zig syntax
    // for that reason we prefixed our keywords with a `_`
    const prefixed = try std.mem.concat(self.allocator, u8, &[_][]const u8{ "_", literal });

    if (std.meta.stringToEnum(TokenMap, prefixed)) |char| {
      ch = char;
    } else {
      ch = TokenMap.ident;
    }

    return ch;
  }

  fn updatePosition(self: *Lexer, wr: WordRange) void {
    self.position = wr.start;
    self.readPosition = wr.end;
  }

  fn init(self: *Lexer, allocator: *std.mem.Allocator, input: []const u8) !void {
    self.allocator = allocator;
    self.input = input;
    self.position = 0;
    self.readPosition = 0;
  }

  fn create(allocator: *std.mem.Allocator, input: []const u8) !*Lexer {
    var l = try allocator.create(Lexer);

    // Initialisation
    try l.init(allocator, input);

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
  const input: []const u8 =
    \\ let five = 5;
    \\ let three = 3;
    \\ let add = function(x, y) {
    \\   return x + y;
    \\ };
    \\
    \\ let result = add(five, ten);
    \\ <>!-/*
  ;

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
      .expectedType = TokenMap._let,
      .expectedLiteral = "let"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "five"
    },
    .{
      .expectedType = TokenMap.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = TokenMap.int,
      .expectedLiteral = "5"
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedLiteral = "let"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "three"
    },
    .{
      .expectedType = TokenMap.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = TokenMap.int,
      .expectedLiteral = "3"
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedLiteral = "let"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "add"
    },
    .{
      .expectedType = TokenMap.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = TokenMap._function,
      .expectedLiteral = "function"
    },
    .{
      .expectedType = TokenMap.lparen,
      .expectedLiteral = "("
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "x"
    },
    .{
      .expectedType = TokenMap.comma,
      .expectedLiteral = ","
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "y"
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
      .expectedType = TokenMap._return,
      .expectedLiteral = "return"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "x"
    },
    .{
      .expectedType = TokenMap.plus,
      .expectedLiteral = "+"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "y"
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap.rbrace,
      .expectedLiteral = "}"
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedLiteral = "let"
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "result"
    },
    .{
      .expectedType = TokenMap.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "add"
    },
    .{
      .expectedType = TokenMap.lparen,
      .expectedLiteral = "("
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "five"
    },
    .{
      .expectedType = TokenMap.comma,
      .expectedLiteral = ","
    },
    .{
      .expectedType = TokenMap.ident,
      .expectedLiteral = "ten"
    },
    .{
      .expectedType = TokenMap.rparen,
      .expectedLiteral = ")"
    },
    .{
      .expectedType = TokenMap.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = TokenMap.lt,
      .expectedLiteral = "<"
    },
    .{
      .expectedType = TokenMap.gt,
      .expectedLiteral = ">"
    },
    .{
      .expectedType = TokenMap.bang,
      .expectedLiteral = "!"
    },
    .{
      .expectedType = TokenMap.minus,
      .expectedLiteral = "-"
    },
    .{
      .expectedType = TokenMap.slash,
      .expectedLiteral = "/"
    },
    .{
      .expectedType = TokenMap.asterisk,
      .expectedLiteral = "*"
    },
    .{
      .expectedType = TokenMap.eof,
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