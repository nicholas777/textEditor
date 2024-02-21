const std = @import("std");
const config = @import("config");

const rope = @import("rope.zig");
const editor = @import("editor.zig");

const curses = @import("curses");

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip(); // Skip the application name

    var arg = args.next();

    var input_file: ?[]const u8 = null;

    while (arg != null) : (arg = args.next()) {
        if (std.mem.eql(u8, arg.?, "--help")) {
            return printHelpMessage();
        } else if (std.mem.eql(u8, arg.?, "--version")) {
            return printVersion();
        } else if (!std.mem.startsWith(u8, arg.?, "-")) {
            input_file = arg.?;
        }
    }

    if (input_file == null) {
        try std.io.getStdOut().writer().print("Fatal: No input file specified\n", .{});
        return;
    }

    var file = std.fs.cwd().openFile(input_file.?, .{}) catch |err| switch (err) {
        error.FileNotFound, error.AccessDenied, error.NameTooLong => {
            try std.io.getStdOut().writer().print("Failed to open file: {s}", .{input_file.?});
            return;
        },
        else => {
            return err;
        },
    };
    defer file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var data: *rope.Rope = try editor.read_file(alloc, file);
    defer {
        data.free_children(alloc);
    }

    const screen = try curses.init(alloc, null);

    try editor.event_loop(alloc, screen, data);

    defer curses.deinit(alloc, screen);
}

const helpMessage =
    \\Usage: text <input-file> [options]
    \\Options:
    \\    --help: Displays this message
    \\    --version: Displays the version
    \\
;

fn printHelpMessage() !void {
    _ = try std.io.getStdOut().write(helpMessage);
}

fn printVersion() !void {
    try std.io.getStdOut().writer().print("{s}\n", .{config.version});
}
