const std = @import("std");
const util = @import("../main.zig");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    var map = &ctx.map;
    var visited = &ctx.visited;
    for (visited.keys()) |k| {
        const char = map.get(k).?;
        if (char != '.') continue;

        try map.put(k, '#');
        const isCycle = try isCycleInMaze(ctx.allocator, map.*, ctx.start_idx);
        if (isCycle) sum += 1;
        try map.put(k, char);
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn isCycleInMaze(allocator: std.mem.Allocator, map: std.AutoHashMap(Vec2, u8), start_idx: Vec2) !bool {
    var curr_dir = map.get(start_idx).?;
    var curr_idx = start_idx;

    const State = struct {
        idx: Vec2,
        dir: u8,
    };

    var visited = std.AutoHashMap(State, void).init(allocator);
    defer visited.deinit();

    while (true) {
        const curr_state = State{ .idx = curr_idx, .dir = curr_dir };

        if (visited.contains(curr_state)) return true;

        try visited.put(curr_state, {});
        var next_idx: Vec2 = undefined;
        if (curr_dir == '^') {
            next_idx = curr_idx - Vec2{ 1, 0 };
        } else if (curr_dir == 'v') {
            next_idx = curr_idx + Vec2{ 1, 0 };
        } else if (curr_dir == '<') {
            next_idx = curr_idx - Vec2{ 0, 1 };
        } else if (curr_dir == '>') {
            next_idx = curr_idx + Vec2{ 0, 1 };
        }

        const next_char = map.get(next_idx) orelse return false;

        if (next_char == '#') {
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
