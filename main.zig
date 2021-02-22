const repl = @import("repl.zig").repl;

pub fn main() !void {
  try repl();
}