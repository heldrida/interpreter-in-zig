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

  pub fn tokenLiteral(self: *Statement) []const u8 {
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

  pub fn statementNode(self: *Statement) Node {
    self.node;
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

  pub fn tokenLiteral(self: *LetStatement) []const u8 {
    return self.token.Literal;
  }
};

pub const LetStatement = struct {
  token: Token, // the token.LET token 
  name: Identifier,
  value: Expression,

  pub fn statementNode() void {

  }

  pub fn tokenLiteral(self: *LetStatement) []const u8 {
    return self.token.literal;
  }
};

pub const ReturnStatement = struct {
  token: Token, // the 'return' token
  returnValue: Expression
};

pub const ExpressionStatement = struct {
  token: Token,
  expression: Expression,

  pub fn statementNode() void {}

  pub fn tokenLiteral(self: *ExpressionStatement) []const u8 {
    return self.token.literal;
  }
};

// The Program Node is the root Node of the AST
// the parser produces
pub const Program = struct {
  statements: std.ArrayList(Statement),

  pub fn init(allocator: *std.mem.Allocator) Program {
    const p = Program {
      .statements = std.ArrayList(Statement).init(allocator)
    };

    return p;
  }

  pub fn deinit(self: *Program) void {
    self.statements.deinit();
  }

  pub fn tokenLiteral(self: *Program) []const u8 {
    if (self.statements.items.len > 0) {
      return self.statements.items[self.statements.items.len-1].tokenLiteral();
    } else {
      return "";
    }
  }
};

test "Program initialisation" {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var p = Program.init(allocator);
  defer p.deinit();

  try p.statements.append(Statement {
    .node = .{
      .letStatement = LetStatement {
        .token = Token {
          .type = TokenMap._let,
          .literal = "let"
        },
        .name = undefined,
        .value = undefined,
      }
    }
  });
  
  std.testing.expectEqualStrings("let", p.tokenLiteral());

  try p.statements.append(Statement {
    .node = .{
      .returnStatement = ReturnStatement {
        .token = Token {
          .type = TokenMap._return,
          .literal = "return"
        },
        .returnValue = undefined
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