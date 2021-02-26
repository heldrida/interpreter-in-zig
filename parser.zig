const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const TokenMap = @import("token.zig").TokenMap;
const std = @import("std");
const ast = @import("ast.zig");

const ParserError = error {
  programInitFailed
};

const Parser = struct {
  allocator: *std.mem.Allocator,
  l: *Lexer,
  curToken: Token,
  peekToken: Token,
  program: ast.Program,
  errors: std.ArrayList(std.ArrayList(u8)),

  pub fn nextToken(self: *Parser) void {
    self.curToken = self.peekToken;

    if (self.l.nextToken()) |tok| { 
      self.peekToken = tok;
    }
  }

  pub fn parseProgram(self: *Parser) !ast.Program {
    while (self.curToken.type != TokenMap.eof) {
      if (self.parseStatement()) |stmt| {
        try self.program.statements.append(stmt);
      }

      self.nextToken();
    }

    return self.program;
  }

  pub fn parseStatement(self: *Parser) ?ast.Statement {
    switch (self.curToken.type) {
      ._let => {
        std.debug.warn("\n It's the let statement \n", .{});
        if (self.parseLetStatement()) |letStatement| {
          return ast.Statement {
            .node = ast.Node {
              .letStatement = letStatement
            }
          };
        } else {
          return null;
        }
      },
      else => {
        return null;
      }
    }
  }

  pub fn parseLetStatement(self: *Parser) ?ast.LetStatement {
    var stmt = ast.LetStatement {
      .token = Token {
        .type = self.curToken.type,
        .literal = self.curToken.literal
      },
      .name = undefined,
      .value = undefined
    };

    if (!self.expectPeek(TokenMap.ident)) {
     return null;
    }

    stmt.name = ast.Identifier {
      .token = Token {
        .type = self.curToken.type,
        .literal = self.curToken.literal
      },
      .value = self.curToken.literal
    };

    if (!self.expectPeek(TokenMap.assign)) {
      return null;
    }

    while (!self.curTokenIs(TokenMap.semicolon)) {
      self.nextToken();
    }

    return stmt;
  }

  pub fn curTokenIs(self: *Parser, t: TokenMap) bool {
    return self.curToken.type == t;
  }

  pub fn peekTokenIs(self: *Parser, t: TokenMap) bool {
    return self.peekToken.type == t;
  }

  pub fn expectPeek(self: *Parser, t: TokenMap) bool {
    if (self.peekTokenIs(t)) {
      self.nextToken();

      return true;
    } else {
      self.peekError(t) catch unreachable;

      return false;
    }
  }

  fn getErrors(self: *Parser) std.ArrayList([]const u8) {
    return self.errors;
  }

  fn peekError(self: *Parser, t: TokenMap) !void {
    const msg = std.ArrayList(u8).init(self.allocator);
    try self.errors.append(msg);
    try std.fmt.format(self.errors.items[self.errors.items.len-1].writer(), "Expected token to be {s}, but got {s}", .{ t, self.peekToken.type });
  }

  pub fn init(allocator: *std.mem.Allocator, l: *Lexer) Parser {
    var p = Parser {
      .allocator = allocator,
      .l = l,
      .curToken = undefined,
      .peekToken = undefined,
      .program = ast.Program.init(allocator),
      .errors = std.ArrayList(std.ArrayList(u8)).init(allocator),
    };

    // Read two tokens, so curToken and peekToken are both set
    p.nextToken();
    p.nextToken();

    return p;
  }

  pub fn deinit(self: *Parser) void {
    self.program.statements.deinit();
  }
};

test "Let statements" {
  const input: []const u8 =
    \\ let five = 5;
    \\ let three = 3;
    \\ let twenty = 20;
  ;

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);

  var p = Parser.init(allocator, l);

  var program = try p.parseProgram();

  if (program.statements.items.len != 3) {
    std.debug.print("Program statements does not contain 3 statements, has {d}\n", .{ program.statements.items.len });
  }

  const expectedIdentifier = struct { 
    expectedType: TokenMap,
    expectedIdentifier: []const u8
  };
  
  const testCases = [_]expectedIdentifier {
    .{
      .expectedType = TokenMap._let,
      .expectedIdentifier = "five"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedIdentifier = "three"
    },
    .{
      .expectedType = TokenMap._let,
      .expectedIdentifier = "twenty"
    }
  };

  for (testCases) |field, i| {
    const stmt = program.statements.items[i];
    std.testing.expect(field.expectedType == stmt.node.letStatement.token.type);
    std.testing.expectEqualStrings(field.expectedIdentifier, stmt.node.letStatement.name.value);
  }
}

test "Error messages" {
  const input: []const u8 = "";

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);

  var p = Parser.init(allocator, l);

  var program = try p.parseProgram();

  try p.peekError(TokenMap._function);
  std.testing.expectEqualStrings("Expected token to be TokenMap._function, but got TokenMap.eof", p.errors.items[p.errors.items.len-1].items);

  try p.peekError(TokenMap._return);
  std.testing.expectEqualStrings("Expected token to be TokenMap._return, but got TokenMap.eof", p.errors.items[p.errors.items.len-1].items);
}

test "Input typos" {
  const input: []const u8 =
    \\ let five 5;
    \\ let = 3;
  ;

  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, input);

  var p = Parser.init(allocator, l);

  var program = try p.parseProgram();

  const testCases = [_][]const u8 {
    "Expected token to be TokenMap.assign, but got TokenMap.int",
    "Expected token to be TokenMap.ident, but got TokenMap.assign"
  };

  for (p.errors.items) |item, i| {
    std.testing.expectEqualStrings(testCases[i], p.errors.items[i].items);
  }
}