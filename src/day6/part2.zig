const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    var map = std.AutoArrayHashMap([2]i64, u8).init(allocator);
    defer map.deinit();

    var start_idx: [2]i64 = undefined;
    var row: i64 = 0;
    var line_len: usize = undefined;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |char, col| {
            try map.put(.{ row, @intCast(col) }, char);
            if (char == '^' or char == 'v' or char == '<' or char == '>') {
                start_idx = .{ row, @intCast(col) };
            }
        }
        row += 1;
    }

    var sum: u64 = 0;
    for (0..@intCast(row)) |i| {
        for (0..line_len) |j| {
            const char = map.get(.{ @intCast(i), @intCast(j) }).?;
            if (char != '.') {
                continue;
            }
            try map.put(.{ @intCast(i), @intCast(j) }, '#');
            const isCycle = try isCycleInMaze(allocator, map, start_idx);
            if (isCycle) {
                sum += 1;
            }
            try map.put(.{ @intCast(i), @intCast(j) }, char);
        }
    }

    std.debug.print("{d}\n", .{sum});
}

fn isCycleInMaze(allocator: std.mem.Allocator, map: std.AutoArrayHashMap([2]i64, u8), start_idx: [2]i64) !bool {
    var curr_dir = map.get(start_idx).?;
    var curr_idx = start_idx;

    const State = struct {
        idx: [2]i64,
        dir: u8,
    };

    var visited = std.AutoArrayHashMap(State, void).init(allocator);
    defer visited.deinit();

    while (true) {
        const curr_state = State{ .idx = curr_idx, .dir = curr_dir };
        if (visited.get(curr_state) != null) {
            return true;
        }
        try visited.put(curr_state, {});
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
        const next_char = map.get(next_idx);
        if (next_char == null) {
            return false;
        }
        if (next_char.? == '#') {
            if (curr_dir == '^') {
                curr_dir = '>';
                next_idx = curr_idx;
            } else if (curr_dir == '>') {
                curr_dir = 'v';
                next_idx = curr_idx;
            } else if (curr_dir == 'v') {
                curr_dir = '<';
                next_idx = curr_idx;
            } else if (curr_dir == '<') {
                curr_dir = '^';
                next_idx = curr_idx;
            }
        }
        curr_idx = next_idx;
    }
}
