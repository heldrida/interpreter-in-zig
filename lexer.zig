const token = @import("token.zig");
const print = @import("std").debug.print;
const expect = @import("std").testing.expect;
const std = @import("std");

const Lexer = struct {
  input: []const u8,
  position: u8 = 0, // current position in input (points to current char)
  readPosition: u8 = 0, // current reading position in input (after current char)
  ch: token.Map = undefined, // current char under examination
  
  pub fn readChar(self: *Lexer) void {
    // Checks if we reached end of input
    // if so sets to 0 (ASCII code for "NUL" char)
    // otherwise, sets `l.ch` to the next char
    if (self.readPosition >= self.input.len) {
      self.ch = token.Map.nul;
    } else {
      print("readChar: {c}\n", .{ self.input[self.readPosition] });
      self.ch = @intToEnum(token.Map, self.input[self.readPosition]);
    }

    self.position = self.readPosition;
    self.readPosition += 1;
  }

  pub fn nextToken(self: *Lexer) token.Token {
    var tok: token.Token = undefined;

    switch (self.ch) {
      token.Map.ident => {
        tok = newToken(token.Map.ident, self.ch);
      },
      token.Map.int => {
        tok = newToken(token.Map.int, self.ch);
      },
      token.Map.assign => {
        tok = newToken(token.Map.assign, self.ch);
      },
      token.Map.plus => {
        tok = newToken(token.Map.plus, self.ch);
      },
      token.Map.semicolon => {
        tok = newToken(token.Map.semicolon, self.ch);
      },
      token.Map.lparen => {
        tok = newToken(token.Map.lparen, self.ch);
      },
      token.Map.rparen => {
        tok = newToken(token.Map.rparen, self.ch);
      },
      token.Map.comma => {
        tok = newToken(token.Map.comma, self.ch);
      },
      token.Map.lbrace => {
        tok = newToken(token.Map.lbrace, self.ch);
      },
      token.Map.rbrace => {
        tok = newToken(token.Map.rbrace, self.ch);
      },
      token.Map.function => {
        tok = newToken(token.Map.function, self.ch);
      },
      token.Map.let => {
        tok = newToken(token.Map.let, self.ch);
      },
      token.Map.eof => {
        tok = newToken(token.Map.eof, self.ch);
      },
      token.Map.nul => {
        tok = newToken(token.Map.nul, self.ch);
      }
    }

    self.readChar();

    return tok;
  }

  pub fn newToken(tokenType: token.Map, ch: token.Map) token.Token {
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
      .input = "var foobar = 5;"
    };
}

test "imports token" {
  expect(token.Map.assign == @intToEnum(token.Map, '='));
  expect(token.Map.semicolon == @intToEnum(token.Map, ';'));
  expect(token.Map.plus == @intToEnum(token.Map, '+'));
}

test "next token\n" {
  const input = "=+(){},;";

  var l = new(input);

  // Initialisation (ch, position, readPosition)
  l.readChar();

  const expectedType = struct {
      expectedType: token.Map,
      expectedLiteral: []const u8
  };
  const tests = [_]expectedType {
    .{
      .expectedType = token.Map.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = token.Map.plus,
      .expectedLiteral = "+"
    },
    .{
      .expectedType = token.Map.lparen,
      .expectedLiteral = "("
    },
    .{
      .expectedType = token.Map.rparen,
      .expectedLiteral = ")"
    },
    .{
      .expectedType = token.Map.lbrace,
      .expectedLiteral = "{"
    },
    .{
      .expectedType = token.Map.rbrace,
      .expectedLiteral = "}"
    },
    .{
      .expectedType = token.Map.comma,
      .expectedLiteral = ","
    },
    .{
      .expectedType = token.Map.semicolon,
      .expectedLiteral = ";"
    },
    .{
      .expectedType = token.Map.nul,
      .expectedLiteral = ""
    }
  };

  for (tests) |field| {
    const tok = l.nextToken();
    // expect(tok.type == field.expectedType);
    // const arr = &[_]tok.literal[0..];
    // expect(std.mem.eql(u8, tok.literal[0..], field.expectedLiteral) == true);
    // print("{s}\n", .{ @enumToInt(tok.type) });
    expect(tok.type == field.expectedType);
  }
}