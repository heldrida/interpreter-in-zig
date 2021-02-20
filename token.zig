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
  // Delimiters
  comma = 44,
  semicolon = 59,
  lparen = 40,
  rparen = 41,
  lbrace = 123,
  rbrace = 125,
  // Keywords
  function = 70,
  let = 76
};
