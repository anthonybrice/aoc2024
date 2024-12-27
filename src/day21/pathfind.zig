const std = @import("std");
const p1 = @import("part1.zig");

const Vec2 = @Vector(2, i64);

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
    dir: Vec2,
};

const directions = [_]Vec2{
    Vec2{ 0, 1 },
    Vec2{ -1, 0 },
    Vec2{ 1, 0 },
    Vec2{ 0, -1 },
};

pub fn dijkstra(
    allocator: std.mem.Allocator,
    maze: std.AutoArrayHashMap(Vec2, u8),
    start: Vec2,
) !struct {
    dist: std.AutoArrayHashMap([2]Vec2, i64),
    prev: std.AutoArrayHashMap([2]Vec2, [2]Vec2),
} {
    var dist = std.AutoArrayHashMap([2]Vec2, i64).init(allocator);
    try dist.put(.{ start, Vec2{ 0, 0 } }, 0);

    var q = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer q.deinit();
    try q.add(.{ .pos = start, .f_score = 0, .dir = Vec2{ 0, 0 } });

    var prev = std.AutoArrayHashMap([2]Vec2, [2]Vec2).init(allocator);

    while (q.count() != 0) {
        const u = q.remove();

        // for each neighbor v of u
        for (directions) |dir| {
            const v = u.pos + dir;
            if (!maze.contains(v)) {
                continue;
            }

            const turn_penalty: i64 =
                if (std.meta.eql(u.dir, Vec2{ 0, 0 }) or
                std.meta.eql(u.dir, dir)) 0 else 100;
            const alt = dist.get(.{ u.pos, u.dir }).? + turn_penalty + 1;

            if (alt < (dist.get(.{ v, dir }) orelse std.math.maxInt(i64))) {
                try dist.put(.{ v, dir }, alt);
                try prev.put(.{ v, dir }, .{ u.pos, u.dir });
                try q.add(.{ .pos = v, .f_score = alt, .dir = dir });
            }
        }
    }

    return .{ .dist = dist, .prev = prev };
}

pub fn shortestPaths(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2) !std.AutoArrayHashMap(Vec2, []Vec2) {
    const dijkstra_result = try dijkstra(allocator, maze, start);
    var dist = dijkstra_result.dist;
    defer dist.deinit();
    var prev = dijkstra_result.prev;
    defer prev.deinit();

    var paths = std.AutoArrayHashMap(Vec2, []Vec2).init(allocator);

    // for each key in maze, find the k in dist with the smallest value
    for (maze.keys()) |k| {
        var flag: i64 = std.math.maxInt(i64);
        var y: [2]Vec2 = undefined;
        for (directions ++ .{Vec2{ 0, 0 }}) |dir| {
            const foo = dist.get(.{ k, dir }) orelse continue;
            if (foo < flag) {
                flag = foo;
                y = .{ k, dir };
            }
        }
        const path = try reconstructPath(allocator, prev, y);
        try paths.put(k, path);
    }

    return paths;
}

fn reconstructPath(allocator: std.mem.Allocator, prev: std.AutoArrayHashMap([2]Vec2, [2]Vec2), current: [2]Vec2) ![]Vec2 {
    var totalPath = std.ArrayList(Vec2).init(allocator);
    defer totalPath.deinit();

    try totalPath.append(current[0]);
    var curr = current;
    while (prev.contains(curr)) {
        curr = prev.get(curr).?;
        try totalPath.append(curr[0]);
    }

    const arr = try totalPath.toOwnedSlice();
    std.mem.reverse(Vec2, arr);

    return arr;
}
