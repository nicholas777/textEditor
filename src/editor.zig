const rope = @import("rope.zig");
const std = @import("std");

pub fn read_file(alloc: std.mem.Allocator, file: std.fs.File) !*rope.Rope {
    var data: *rope.Rope = try alloc.create(rope.Rope);
    data.left = null;
    data.right = null;
    data.data = try alloc.alloc(u8, 16);
    data.weight = try file.reader().read(data.data.?);

    var buf: [16]u8 = undefined;
    while (true) {
        var read: usize = try file.reader().read(&buf);
        if (read == 0) break;

        var temp: *rope.RopeNode = try alloc.create(rope.RopeNode);
        temp.data = null;

        temp.weight = calc_weights(data);

        var right: *rope.RopeNode = try alloc.create(rope.RopeNode);
        right.data = try alloc.dupe(u8, &buf);
        right.weight = read;
        right.left = null;
        right.right = null;

        temp.left = data;
        temp.right = right;
        data = temp;
    }

    return data;
}

fn calc_weights(node: *rope.RopeNode) usize {
    if (node.is_leaf()) return node.weight;

    var result: usize = 0;
    if (node.left != null) result += calc_weights(node.left.?);
    if (node.right != null) result += calc_weights(node.right.?);
    return result;
}

const curses = @import("curses");

fn print_node(screen: *curses.Screen, node: *rope.RopeNode) void {
    _ = node;
    _ = screen;
}

fn print_file(screen: *curses.Screen, node: *rope.RopeNode) void {
    if (node.is_leaf()) {
        curses.cmd.print(screen, node.data.?);
        return;
    }

    if (node.left != null) print_file(screen, node.left.?);
    if (node.right != null) print_file(screen, node.left.?);
}

pub fn event_loop(alloc: std.mem.Allocator, screen: *curses.Screen, file: *rope.Rope) !void {
    var is_command: bool = false;

    var orig_x: usize = 0;
    var orig_y: usize = 0;

    print_file(screen, file);
    try curses.draw_screen(screen);

    while (true) {
        const char = try curses.input.read_char(screen);

        switch (char) {
            .Colon => {
                if (!is_command) {
                    orig_x = screen.cursor_x;
                    orig_y = screen.cursor_y;

                    curses.cmd.color_line(screen, screen.lines - 1, .Magenta, .White);
                    curses.cmd.print_char_at(screen, ':', 0, screen.lines - 1);

                    is_command = true;
                } else {
                    curses.cmd.print_char(screen, @intFromEnum(char));
                }
            },
            .Newline, .Carriage => {
                if (is_command) {
                    const command = try curses.cmd.read_range(screen, alloc, 1, screen.lines - 1, screen.cursor_x - 1);
                    curses.cmd.cursor_home(screen);
                    curses.cmd.clear_line(screen, screen.lines - 1);

                    if (std.mem.eql(u8, command, "q")) break;

                    alloc.free(command);

                    is_command = false;
                    curses.cmd.move_cursor(screen, orig_x, orig_y);
                } else {
                    curses.cmd.new_line(screen);
                }
            },
            .Backspace, .Delete => {
                if (screen.cursor_x == 0 and screen.cursor_y != 0) {
                    curses.cmd.move_cursor(screen, screen.columns - 1, screen.cursor_y - 1);
                    curses.cmd.delete_at_cursor(screen);
                    continue;
                }

                if (screen.cursor_y == screen.lines - 1) {
                    if (screen.cursor_x != 1) {
                        curses.cmd.cursor_left(screen);
                        curses.cmd.delete_at_cursor(screen);
                    }
                } else {
                    curses.cmd.cursor_left(screen);
                    curses.cmd.delete_at_cursor(screen);
                }
            },
            .ArrowUp => {
                if (!is_command) curses.cmd.cursor_up(screen);
            },
            .ArrowDown => {
                if (!is_command) curses.cmd.cursor_down(screen);
            },
            .ArrowLeft => {
                if (!is_command) curses.cmd.cursor_left(screen);
            },
            .ArrowRight => {
                if (!is_command) curses.cmd.cursor_right(screen);
            },
            else => {
                curses.cmd.print_char(screen, @intFromEnum(char));
            },
        }

        try curses.draw_screen(screen);
    }
}
