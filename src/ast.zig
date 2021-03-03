const token = @import("./token.zig");
const std = @import("std");

// Types
const Token = token.Token;
const TokenMap = token.TokenMap;

const Statements = enum {
  letStatement,
  returnStatement,
  expressionStatement
};

pub const Node = union(Statements) {
  letStatement: LetStatement,
  returnStatement: ReturnStatement,
  expressionStatement: ExpressionStatement
};

pub const Statement = struct {
  node: Node,

  pub fn tokenLiteral(self: *@This()) []const u8 {
    switch (self.node) {
      .letStatement => |content| {
        return content.token.literal;
      },
      .returnStatement => |content| {
        return content.token.literal;
      },
      .expressionStatement => |content| {
        return content.token.literal;
      }
    }
  }

  pub fn statementNode(self: *@This()) Node {
    self.node;
  }

  pub fn string(self: *@This()) ![]u8 {
    switch (self.node) {
      .letStatement => |content| {
        return try self.node.letStatement.string();
      },
      .returnStatement => |content| {
        return try self.node.returnStatement.string();
      },
      .expressionStatement => |content| {
        return try self.node.expressionStatement.string();
      }
    }
  }
};

const Expression = struct {  
  pub fn expressionNode() void {

  }
};

pub const Identifier = struct {
  token: Token, // the token.IDENT token
  value: []const u8,

  pub fn expressionNode() void {

  }

  pub fn tokenLiteral(self: *@This()) []const u8 {
    return self.token.Literal;
  }
};

pub const LetStatement = struct {
  alloc: *std.mem.Allocator,
  token: Token, // the token.LET token 
  name: Identifier,
  value: Expression,
  stringBuf: std.ArrayList(std.ArrayList(u8)),

  pub fn statementNode() void {

  }

  pub fn tokenLiteral(self: *@This()) []const u8 {
    return self.token.literal;
  }

  pub fn string(self: *@This()) ![]u8 {
    const msg = std.ArrayList(u8).init(self.alloc);

    try self.stringBuf.append(msg);

    // TODO: expression value
    try std.fmt.format(self.stringBuf.items[self.stringBuf.items.len-1].writer(), "{s} {s} = ;", .{ self.tokenLiteral(), self.name.value });

    return self.stringBuf.items[0].toOwnedSlice();
  }
};

pub const ReturnStatement = struct {
  alloc: *std.mem.Allocator,
  token: Token, // the 'return' token
  returnValue: Expression,
  stringBuf: std.ArrayList(std.ArrayList(u8)),

  pub fn tokenLiteral(self: *@This()) []const u8 {
    return self.token.literal;
  }
  
  pub fn string(self: *@This()) ![]u8 {
    const msg = std.ArrayList(u8).init(self.alloc);

    try self.stringBuf.append(msg);

    // TODO: expression value
    try std.fmt.format(self.stringBuf.items[self.stringBuf.items.len-1].writer(), "{s} ;", .{ self.tokenLiteral() });

    return self.stringBuf.items[0].toOwnedSlice();
  }
};

pub const ExpressionStatement = struct {
  token: Token,
  expression: Expression,

  pub fn statementNode() void {}

  pub fn tokenLiteral(self: *@This()) []const u8 {
    return self.token.literal;
  }

  pub fn string(self: *@This()) ![]u8 {
    return "";
  }
};

// The Program Node is the root Node of the AST
// the parser produces
pub const Program = struct {
  alloc: *std.mem.Allocator,
  statements: std.ArrayList(Statement),
  stringBuf: std.ArrayList(std.ArrayList(u8)),

  pub fn init(allocator: *std.mem.Allocator) Program {
    const p = Program {
      .statements = std.ArrayList(Statement).init(allocator),
      .stringBuf = std.ArrayList(std.ArrayList(u8)).init(allocator),
      .alloc = allocator
    };

    return p;
  }

  pub fn deinit(self: *@This()) void {
    self.statements.deinit();
  }

  pub fn tokenLiteral(self: *@This()) []const u8 {
    if (self.statements.items.len > 0) {
      return self.statements.items[self.statements.items.len-1].tokenLiteral();
    } else {
      return "";
    }
  }

  pub fn string(self: *@This()) ![]u8 {
    const msg = std.ArrayList(u8).init(self.alloc);

    try self.stringBuf.append(msg);

    for (self.statements.items) |stmt, i| {
      try std.fmt.format(self.stringBuf.items[self.stringBuf.items.len-1].writer(), "{s}", .{ self.statements.items[i].string() });
    }

    return self.stringBuf.items[0].toOwnedSlice();
  }
};

test "Program.string()" {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var p = Program.init(allocator);
  defer p.deinit();

  try p.statements.append(Statement {
    .node = .{
      .letStatement = LetStatement {
        .alloc = allocator,
        .token = Token {
          .type = TokenMap._let,
          .literal = "let"
        },
        .name = Identifier {
          .token = Token {
            .type = TokenMap._let,
            .literal = "let"
          },
          .value = "foobar"
        },
        .value = undefined,
        .stringBuf = std.ArrayList(std.ArrayList(u8)).init(allocator)
      }
    }
  });

  try p.statements.append(Statement {
    .node = .{
      .returnStatement = ReturnStatement {
        .alloc = allocator,
        .token = Token {
          .type = TokenMap._return,
          .literal = "return"
        },
        .returnValue = undefined,
        .stringBuf = std.ArrayList(std.ArrayList(u8)).init(allocator)
      }
    }
  });

  testExpectEqlStrings("let foobar = ;return ;", try p.string());
}

test "Program initialisation" {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var p = Program.init(allocator);
  defer p.deinit();

  try p.statements.append(Statement {
    .node = .{
      .letStatement = LetStatement {
        .alloc = allocator,
        .token = Token {
          .type = TokenMap._let,
          .literal = "let"
        },
        .name = undefined,
        .value = undefined,
        .stringBuf = std.ArrayList(std.ArrayList(u8)).init(allocator)
      }
    }
  });
  
  std.testing.expectEqualStrings("let", p.tokenLiteral());

  try p.statements.append(Statement {
    .node = .{
      .returnStatement = ReturnStatement {
        .alloc = allocator,
        .token = Token {
          .type = TokenMap._return,
          .literal = "return"
        },
        .returnValue = undefined,
        .stringBuf = std.ArrayList(std.ArrayList(u8)).init(allocator)
      }
    }
  });

  std.testing.expectEqualStrings("return", p.tokenLiteral());

  const expectedType = struct {
    expectedLiteral: []const u8
  };

  const testCases = [_]expectedType {
    .{
      .expectedLiteral = "let"
    },
    .{
      .expectedLiteral = "return"
    }
  };

  for (p.statements.items) |stmt, i| {
    switch (stmt.node) {
      .letStatement => |content| {
        testExpectEqlStrings(testCases[i].expectedLiteral, content.token.literal);
      },
      .returnStatement => |content| {
        testExpectEqlStrings(testCases[i].expectedLiteral, content.token.literal);
      },
      .expressionStatement => |content| {
        // TODO
      }
    }
  }
}

fn testExpectEqlStrings(a: []const u8, b: []const u8) void {
  std.testing.expectEqualStrings(a, b);
}