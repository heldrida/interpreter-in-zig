const token = @import("./token.zig");
const std = @import("std");

// Types
const Token = token.Token;
const TokenMap = token.TokenMap;

const Statements = enum {
  letStatement
};

pub const Node = union(Statements) {
  letStatement: LetStatement
};

pub const Statement = struct {
  node: Node,

  pub fn tokenLiteral(self: *Statement) []const u8 {
    switch (self.node) {
      .letStatement => |content| {
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
      return self.statements.items[0].tokenLiteral();
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
}