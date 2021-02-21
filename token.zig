const std = @import("std");

pub const Token = struct {
  type: TokenMap,
  literal: []const u8
};

pub const TokenMap = enum(u8) {
  nul = 0,
  eof = 4,
  // Identifiers and literals
  ident = 9,
  int = 48,
  // Operators
  assign = 61,
  plus = 43,
  minus = 45,
  bang = 33,
  asterisk = 42,
  slash = 47,
  lt = 60,
  gt = 62,
  // Delimiters
  comma = 44,
  semicolon = 59,
  lparen = 40,
  rparen = 41,
  lbrace = 123,
  rbrace = 125,
  // Keywords
  _function = 70,
  _let = 76
};

// pub const TokenKeywords = [_][]const u8{ Let[0..], Fn[0..] };
pub const TokenKeywords = [2]TokenMap { TokenMap._function, TokenMap._let };

test "iterate keywords" {
  const expectedType = struct {
      expectedType: TokenMap,
      expectedLiteral: []const u8
  };
  const testCases = [_]expectedType {
    .{
      .expectedType = TokenMap._function,
      .expectedLiteral = "function"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedLiteral = "let"
    }
  };

  for (testCases) |value, i| {    
    std.testing.expect(value.expectedType == TokenKeywords[i]);
  }
}