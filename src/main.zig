const std = @import("std");
const repl = @import("repl.zig").repl;
const Lexer = @import("lexer.zig").Lexer;

pub fn main() !void {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  defer arena.deinit();

  const allocator = &arena.allocator;

  var l = try Lexer.create(allocator, "");

  try repl(l);
}