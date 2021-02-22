const builtin = @import("builtin");
const std = @import("std");
const io = std.io;
const fmt = std.fmt;

pub fn repl() !void {
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn();

    try stdout.print("Welcome to the Vascode programming language!\n", .{});

    const answer = std.crypto.random.intRangeLessThan(u8, 0, 100) + 1;

    while (true) {
        try stdout.print("> ", .{});

        // Buffer
        var buf: [50]u8 = undefined;

        // Read the user input
        const cmd = try stdin.read(&buf);

        // Check the input length
        // considering the buffer size
        if (cmd == buf.len) {
            try stdout.print("Oops! The command is quite long, mind shortening?\n", .{});
            continue;
        }

        const line = std.mem.trimRight(u8, buf[0..cmd], "\r\n");

        try stdout.print("{s}\n", .{ line });
    }
}