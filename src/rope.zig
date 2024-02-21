const std = @import("std");

pub const Rope = RopeNode;

pub const RopeNode = struct {
    weight: usize = 0,
    data: ?[]u8 = null,
    left: ?*RopeNode = null,
    right: ?*RopeNode = null,

    pub fn is_leaf(self: *RopeNode) bool {
        return self.data != null and self.left == null and self.right == null;
    }

    pub fn print(self: *RopeNode) !void {
        try print_recurse(self, 0);
    }

    pub fn print_recurse(node: *RopeNode, depth: usize) !void {
        if (depth != 0) try std.io.getStdOut().writer().writeByteNTimes('\t', depth);
        try std.io.getStdOut().writer().print("Weight: {}\n", .{node.weight});

        if (depth != 0) try std.io.getStdOut().writer().writeByteNTimes('\t', depth);
        if (node.data != null) {
            try std.io.getStdOut().writer().print("Data: {s}\n", .{node.data.?[0..node.weight]});
        }

        _ = try std.io.getStdOut().write("\n");

        if (node.left != null) try print_recurse(node.left.?, depth + 1);
        if (node.right != null) try print_recurse(node.right.?, depth + 1);
    }

    pub fn free_children(node: *RopeNode, alloc: std.mem.Allocator) void {
        if (node.left != null) free_children(node.left.?, alloc);
        if (node.right != null) free_children(node.right.?, alloc);

        alloc.destroy(node);
    }
};
