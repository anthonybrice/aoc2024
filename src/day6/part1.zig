const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var map = std.AutoArrayHashMap([2]i64, V).init(allocator);
    defer map.deinit();

    var start_idx: [2]i64 = undefined;
    var row: i64 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |char, col| {
            // std.debug.print("row: {d}, col: {d}, char: {c}\n", .{ row, col, char });
            try map.put(.{ row, @intCast(col) }, V{ .char = char, .visited = false });
            if (char == '^' or char == 'v' or char == '<' or char == '>') {
                start_idx = .{ row, @intCast(col) };
            }
        }
        row += 1;
    }

    var curr_dir = map.get(start_idx).?.char;
    var curr_idx = start_idx;
    while (true) {
        // std.debug.print("curr_dir: {c}\n", .{curr_dir});
        // std.debug.print("curr_idx: {any}\n", .{curr_idx});
        const curr_char = map.get(curr_idx).?.char;
        try map.put(curr_idx, V{ .char = curr_char, .visited = true });
        var next_idx: [2]i64 = undefined;
        if (curr_dir == '^') {
            next_idx = .{ curr_idx[0] - 1, curr_idx[1] };
        } else if (curr_dir == 'v') {
            next_idx = .{ curr_idx[0] + 1, curr_idx[1] };
        } else if (curr_dir == '<') {
            next_idx = .{ curr_idx[0], curr_idx[1] - 1 };
        } else if (curr_dir == '>') {
            next_idx = .{ curr_idx[0], curr_idx[1] + 1 };
        }
        // std.debug.print("next_idx: {any}\n", .{next_idx});
        const next_char = map.get(next_idx);
        // std.debug.print("next_char: {c}\n", .{next_char.?});
        if (next_char == null) break;
        if (next_char.?.char == '#') {
            if (curr_dir == '^') {
                curr_dir = '>';
                next_idx = .{ curr_idx[0], curr_idx[1] + 1 };
            } else if (curr_dir == '>') {
                curr_dir = 'v';
                next_idx = .{ curr_idx[0] + 1, curr_idx[1] };
            } else if (curr_dir == 'v') {
                curr_dir = '<';
                next_idx = .{ curr_idx[0], curr_idx[1] - 1 };
            } else if (curr_dir == '<') {
                curr_dir = '^';
                next_idx = .{ curr_idx[0] - 1, curr_idx[1] };
            }
        }
        curr_idx = next_idx;
    }

    var map_iter = map.iterator();
    var sum: u64 = 0;
    while (map_iter.next()) |entry| {
        if (entry.value_ptr.*.visited == true) sum += 1;
    }
    std.debug.print("{d}\n", .{sum});
}

const V = struct {
    char: u8,
    visited: bool,
};
