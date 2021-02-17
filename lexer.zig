const token = @import("token.zig");
const print = @import("std").debug.print;
const expect = @import("std").testing.expect;
const std = @import("std");
const Lexer = struct {
  input: []const u8,
  position: u8 = 0, // current position in input (points to current char)
  readPosition: u8 = 0, // current reading position in input (after current char)
  ch: u8 = undefined, // current char under examination
  
  pub fn readChar(self: *Lexer) void {
    // Checks if we reached end of input
    // if so sets to 0 (ASCII code for "NUL" char)
    // otherwise, sets `l.ch` to the next char
    if (self.readPosition >= self.input.len) {
      self.ch = undefined;
    } else {
      self.ch = self.input[self.readPosition];
    }

    self.position = self.readPosition;
    self.readPosition += 1;
  }

  pub fn nextToken(self: *Lexer) token.Token {
    var tok: token.Token = undefined;

    // switch (self.ch) {
    //     std.mem.eql(u8, &arr, token.ASSIGN) => {
    //       tok = newToken(token.ASSIGN, l.ch);
    //     },
    //     token.SEMICOLON => {
    //       tok = newToken(token.SEMICOLON, l.ch);
    //     },
    //     token.LPAREN => {
    //       tok = newToken(token.LPAREN, l.ch);
    //     },
    //     token.RPAREN => {
    //       tok = newToken(token.RPAREN, l.ch);
    //     },
    //     token.COMMA => {
    //       tok = newToken(token.COMMA, l.ch);
    //     },
    //     token.PLUS => {
    //       tok = newToken(token.PLUS, l.ch);
    //     },
    //     token.LBRACE => {
    //       tok = newToken(token.LBRACE, l.ch);
    //     },
    //     token.RBRACE => {
    //       tok = newToken(token.RBRACE, l.ch);
    //     },
    //     0 => {
    //       tok.Type = token.EOF;
    //       tok.Literal = "";
    //     }
    // }

    const arr = [_]u8{ self.ch };

    if (std.mem.eql(u8, &arr, token.ASSIGN)) {
      tok = newToken(token.ASSIGN, self.ch); 
    } else if (std.mem.eql(u8, &arr, token.SEMICOLON)) {
      tok = newToken(token.SEMICOLON, self.ch);
    } else if (std.mem.eql(u8, &arr, token.LPAREN)) {
      tok = newToken(token.LPAREN, self.ch);
    } else if (std.mem.eql(u8, &arr, token.RPAREN)) {
      tok = newToken(token.RPAREN, self.ch);
    } else if (std.mem.eql(u8, &arr, token.COMMA)) {
      tok = newToken(token.COMMA, self.ch);
    } else if (std.mem.eql(u8, &arr, token.PLUS)) {
      tok = newToken(token.PLUS, self.ch);
    } else if (std.mem.eql(u8, &arr, token.LBRACE)) {
      tok = newToken(token.LBRACE, self.ch);
    } else if (std.mem.eql(u8, &arr, token.RBRACE)) {
      tok = newToken(token.RBRACE, self.ch);
    } else {
      tok.type = token.EOF;
      tok.literal = undefined;
    }

    self.readChar();

    return tok;
  }

  pub fn newToken(tokenType: []const u8, ch: u8) token.Token {
    return token.Token{
      .type = tokenType,
      .literal = ch
    };
  }
};

pub fn new(input: []const u8) Lexer {
  const l = Lexer {
    .input = input
  };

  return l;
}

test "struct usage" {
    const l = Lexer {
      .input = "foobar"
    };
}

test "imports token" {
  expect(token.ASSIGN == "=");
  expect(token.PLUS == "+");
  expect(token.FUNCTION == "FUNCTION");
}

test "next token" {
  const input = "=+(){},;";

  var l = new(input);

  // Initialisation (ch, position, readPosition)
  l.readChar();

  const expectedType = struct {
      expectedType: []const u8,
      expectedLiteral: []const u8
  };
  const tests = [_]expectedType {
    .{
      .expectedType = token.ASSIGN,
      .expectedLiteral = "="
    },
    .{
      .expectedType = token.PLUS,
      .expectedLiteral = "+"
    },
    .{
      .expectedType = token.LPAREN,
      .expectedLiteral = "("
    },
    .{
      .expectedType = token.RPAREN,
      .expectedLiteral = ")"
    },
    .{
      .expectedType = token.LBRACE,
      .expectedLiteral = "{"
    },
    .{
      .expectedType = token.RBRACE,
      .expectedLiteral = "}"
    },
    .{
      .expectedType = token.COMMA,
      .expectedLiteral = ","
    },
    .{
      .expectedType = token.SEMICOLON,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = token.EOF,
      .expectedLiteral = ""
    }
  };

  for (tests) |field| {
    const tok = l.nextToken();
    expect(std.mem.eql(u8, tok.type, field.expectedType) == true);
  }
}