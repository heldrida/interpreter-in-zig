const token = @import("token.zig");
const print = @import("std").debug.print;
const expect = @import("std").testing.expect;
const std = @import("std");

const Lexer = struct {
  input: []const u8,
  // current position in input (points to current char)
  position: u8,
  // current reading position in input (after current char)
  readPosition: u8,
  // current char under examination
  ch: token.Map,
  
  // Checks if we reached end of input
  // if so sets to 0 (ASCII code for "NUL" char)
  // otherwise, sets `l.ch` to the next char
  fn readChar(self: *Lexer) void {
    if (self.readPosition >= self.input.len) {
      self.ch = token.Map.nul;
    } else if (isLetter(self.input[self.readPosition])) {
      var i: u8 = self.readPosition;

      while (i < self.input[self.readPosition..].len): (i += 1) {
        if (!isLetter(self.input[i])) {
          self.position = self.readPosition;
          self.readPosition = i;
          break;
        }
      }

      if (std.mem.eql(u8, self.input[self.position..self.readPosition], "let")) {
        self.ch = token.Map.let;
      }

      return;
    } else {
      self.ch = @intToEnum(token.Map, self.input[self.readPosition]);
    }

    self.position = self.readPosition;
    self.readPosition += 1;
  }

  fn isLetter(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'B');
  }

  fn nextToken(self: *Lexer) token.Token {
    var tok: token.Token = undefined;

    if (isLetter(@enumToInt(self.ch))) {
      tok = newToken(token.Map.nul, self.ch);
      return tok;
    }

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

  fn newToken(tokenType: token.Map, ch: token.Map) token.Token {
    return token.Token{
      .type = tokenType,
      .literal = ch
    };
  }

  fn init(self: *Lexer, input: []const u8, position: u8, readPosition: u8) void {
    self.input = input;
    self.position = position;
    self.readPosition = readPosition;
    self.ch = @intToEnum(token.Map, self.input[self.position]);    
  }

  fn create(allocator: *std.mem.Allocator, input: []const u8) !*Lexer {
    var l = try allocator.create(Lexer);

    // Initialisation
    l.init(input, 0, 1);

    return l;
  }
};

test "Verifies token types" {
  const input: []const u8 = "=+let(){},;";

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);

  const expectedType = struct {
      expectedType: token.Map,
      expectedLiteral: []const u8
  };
  const testCases = [_]expectedType {
    .{
      .expectedType = token.Map.assign,
      .expectedLiteral = "="
    },
    .{
      .expectedType = token.Map.plus,
      .expectedLiteral = "+"
    },
    .{
      .expectedType = token.Map.let,
      .expectedLiteral = "let"
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

  for (testCases) |field| {
    const tok = l.nextToken();

    expect(tok.type == field.expectedType);
  }
}