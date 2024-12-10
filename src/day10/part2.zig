const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var height_map = std.AutoArrayHashMap([2]usize, u64).init(allocator);
    var row: usize = 0;
    var line_len: usize = undefined;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |c, col| {
            try height_map.put(.{ row, col }, c - '0');
        }
        row += 1;
    }

    var sum: u64 = 0;
    for (0..row) |i| {
        for (0..line_len) |j| {
            if (height_map.get(.{ i, j }) == 0) {
                sum += try find_trail(allocator, height_map, i, j);
            }
        }
    }

    std.debug.print("{d}\n", .{sum});
}

const directions = [_][2]i64{
    .{ -1, 0 }, // up
    .{ 1, 0 }, // down
    .{ 0, -1 }, // left
    .{ 0, 1 }, // right
};

fn find_trail(
    allocator: std.mem.Allocator,
    height_map: anytype,
    i: usize,
    j: usize,
) !usize {
    var stack = std.ArrayList([2]usize).init(allocator);
    defer stack.deinit();
    try stack.append(.{ i, j });
    // std.debug.print("start: {d}, {d}\n", .{ i, j });

    var nines: u64 = 0;
    while (stack.items.len > 0) {
        const pos = stack.pop();
        const current_value = height_map.get(pos).?;

        if (current_value == 9) {
            nines += 1;
        }

        for (directions) |dir| {
            const new_i = @as(i64, @intCast(pos[0])) + dir[0];
            const new_j = @as(i64, @intCast(pos[1])) + dir[1];
            if (new_i < 0 or new_j < 0) continue;

            const next_value = height_map.get(.{ @intCast(new_i), @intCast(new_j) }) orelse continue;
            if (next_value == current_value + 1) {
                try stack.append(.{ @intCast(new_i), @intCast(new_j) });
            }
        }
    }

    // std.debug.print("nines: {d}\n", .{nines});
    return nines;
}
