pub const TokenType: []const u8;

pub const Token = struct {
    type: []const u8,
    literal: u8
};

pub const ILLEGAL = "ILLEGAL";
pub const EOF = "EOF";

// Identifiers and literals
pub const IDENT = "IDENT"; // add, foobar, x, y, ...
pub const INT = "INT"; // 123456

// Operators
pub const ASSIGN = "=";
pub const PLUS = "+";

// Delimiters
pub const COMMA = ",";
pub const SEMICOLON = ";";
pub const LPAREN = "(";
pub const RPAREN = ")";
pub const LBRACE = "{";
pub const RBRACE = "}";

// Keywords
pub const FUNCTION = "FUNCTION";
pub const LET = "LET";