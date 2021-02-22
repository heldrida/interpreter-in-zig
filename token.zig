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
  _let = 76,
  _return = 77,
  _if = 78,
  _true = 79,
  _false = 80,
  _else = 81
};