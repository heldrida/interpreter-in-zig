const builtin = @import("builtin");
const std = @import("std");
const io = std.io;
const fmt = std.fmt;
const Lexer = @import("lexer.zig").Lexer;
const TokenMap = @import("token.zig").TokenMap;

pub fn repl(l: *Lexer) !void {
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn();

    try stdout.print("Welcome to the Vascode programming language!\n", .{});

    const answer = std.crypto.random.intRangeLessThan(u8, 0, 100) + 1;

    while (true) {
        try stdout.print("> ", .{});

        // Buffer
        var buf: [50]u8 = undefined;

        // Read the user input
        // the number of bytes written (if memory serves)
        const number_of_bytes = try stdin.read(&buf);

        // Check the input length
        // considering the buffer size
        if (number_of_bytes == buf.len) {
            try stdout.print("Oops! The command is quite long, mind shortening?\n", .{});
            continue;
        }

        // Trim
        const line = std.mem.trimRight(u8, buf[0..number_of_bytes], "\r\n");

        // Set new input
        try l.new(line);

        while (l.nextToken()) |tok| {
          if (tok.type == TokenMap.eof) break;
          try stdout.print("{s}\n", .{ tok.literal });
        }
    }
}