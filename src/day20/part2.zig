const std = @import("std");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    const start = try findChar(ctx.maze, 'S');
    const end = try findChar(ctx.maze, 'E');

    const path = try aStar(ctx.allocator, ctx.maze, start, end);
    defer ctx.allocator.free(path);

    // printMaze(maze, row, cols);

    // Find all positions with a distance of 20 or less and a path length of 100 or more between them
    var cheats = std.AutoArrayHashMap(Vec2, std.ArrayList(Vec2)).init(ctx.allocator);
    defer {
        for (cheats.values()) |l| {
            l.deinit();
        }
        cheats.deinit();
    }

    var cheat_times = std.AutoArrayHashMap(u64, u64).init(ctx.allocator);
    defer cheat_times.deinit();
    for (path, 0.., 101..) |pos1, cheat_start, i| {
        if (i >= path.len) {
            break;
        }
        for (path[i..], 0..) |pos2, j| {
            const cheat_end = i + j;
            const cheat_d: usize = @intCast(manhattanDistance(pos1, pos2));
            if (cheat_d > 20) continue;
            const path_d: usize = cheat_end - cheat_start;
            const saved_d = path_d - cheat_d;
            if (saved_d >= 100) {
                var l = cheats.get(pos1) orelse std.ArrayList(Vec2).init(ctx.allocator);
                try l.append(pos2);
                try cheats.put(pos1, l);
                const v = cheat_times.get(saved_d) orelse 0;
                try cheat_times.put(saved_d, v + 1);
            }
        }
    }

    var sum: usize = 0;
    for (cheats.values()) |v| {
        sum += v.items.len;
    }

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn printMaze(maze: std.AutoArrayHashMap(Vec2, u8), rows: i64, cols: i64) void {
    for (0..@intCast(rows)) |i| {
        for (0..@intCast(cols)) |j| {
            const pos: Vec2 = .{ @intCast(j), @intCast(i) };
            const char = maze.get(pos).?;
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}

fn manhattanDistance(a: Vec2, b: Vec2) i64 {
    const x: i64 = @intCast(@abs(a[0] - b[0]));
    const y: i64 = @intCast(@abs(a[1] - b[1]));
    return x + y;
}

fn lessThan(context: void, a: PqItem, b: PqItem) std.math.Order {
    _ = context;
    return std.math.order(a.f_score, b.f_score);
}

const PqItem = struct {
    pos: Vec2,
    f_score: i64,
};

const directions = [_]Vec2{
    Vec2{ -1, 0 },
    Vec2{ 1, 0 },
    Vec2{ 0, -1 },
    Vec2{ 0, 1 },
};

pub fn aStar(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2, goal: Vec2) ![]Vec2 {
    var open_set = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer open_set.deinit();
    try open_set.add(.{ .pos = start, .f_score = manhattanDistance(start, goal) });

    var came_from = std.AutoArrayHashMap(Vec2, Vec2).init(allocator);
    defer came_from.deinit();

    var g_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    while (open_set.count() != 0) {
        const current = open_set.remove();

        if (std.meta.eql(current.pos, goal)) {
            return reconstructPath(allocator, came_from, current.pos);
        }

        for (directions) |dir| {
            const neighbor = current.pos + dir;
            if (!maze.contains(neighbor) or maze.get(neighbor) == '#') {
                continue;
            }

            const tentative_g_score: i64 = g_score.get(current.pos).? + 1;

            if (tentative_g_score < (g_score.get(neighbor) orelse std.math.maxInt(i64))) {
                try came_from.put(neighbor, current.pos);
                try g_score.put(neighbor, tentative_g_score);
                try open_set.add(.{
                    .pos = neighbor,
                    .f_score = tentative_g_score + manhattanDistance(neighbor, goal),
                });
            }
        }
    }

    return error.PathNotFound;
}

fn reconstructPath(allocator: std.mem.Allocator, cameFrom: std.AutoArrayHashMap(Vec2, Vec2), current: Vec2) ![]Vec2 {
    var totalPath = std.ArrayList(Vec2).init(allocator);
    defer totalPath.deinit();

    try totalPath.append(current);
    var curr = current;
    while (cameFrom.contains(curr)) {
        curr = cameFrom.get(curr).?;
        try totalPath.append(curr);
    }

    return totalPath.toOwnedSlice();
}

fn findChar(maze: std.AutoArrayHashMap(Vec2, u8), char: u8) !Vec2 {
    var iter = maze.iterator();
    while (iter.next()) |entry| {
        if (entry.value_ptr.* == char) {
            return entry.key_ptr.*;
        }
    }
    return error.NotFound;
}
