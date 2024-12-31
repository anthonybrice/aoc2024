const std = @import("std");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    const start = findReindeer(ctx.maze).pos;
    const end = findEnd(ctx.maze);

    var foos = try dijkstra(ctx.allocator, ctx.maze, start, end);
    defer {
        foos.dist.deinit();
        for (foos.prev.values()) |val| {
            val.deinit();
        }
        foos.prev.deinit();
    }
    const sum = try countNodesFromEnd(ctx.allocator, foos.prev, end);

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

const direction = enum {
    North,
    East,
    South,
    West,
};

const Reindeer = struct {
    dir: direction,
    pos: Vec2,
};

pub fn findReindeer(maze: []const []const u8) Reindeer {
    var pos: Vec2 = undefined;
    for (maze, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'S') {
                pos = Vec2{ @intCast(col), @intCast(row) };
                return Reindeer{ .dir = direction.East, .pos = pos };
            }
        }
    }
    unreachable;
}

pub fn findEnd(maze: []const []const u8) Vec2 {
    for (maze, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'E') {
                return Vec2{ @intCast(col), @intCast(row) };
            }
        }
    }
    unreachable;
}

const directions = [_]Vec2{
    Vec2{ 1, 0 },
    Vec2{ -1, 0 },
    Vec2{ 0, 1 },
    Vec2{ 0, -1 },
};

fn heuristic(a: Vec2, b: Vec2) i64 {
    const x: i64 = @intCast(@abs(a[0] - b[0]));
    const y: i64 = @intCast(@abs(a[1] - b[1]));
    return x + y;
}

const PqItem = struct {
    pos: Vec2,
    dir: Vec2,
    score: i64,
};

fn lessThan(context: void, a: PqItem, b: PqItem) std.math.Order {
    _ = context;
    return std.math.order(a.score, b.score);
}

fn countNodesFromEnd(allocator: std.mem.Allocator, prev: std.AutoArrayHashMap([2]Vec2, std.ArrayList([2]Vec2)), end: Vec2) !usize {
    var seats = std.AutoArrayHashMap(Vec2, void).init(allocator);
    defer seats.deinit();

    var visited = std.AutoArrayHashMap([2]Vec2, void).init(allocator);
    defer visited.deinit();

    var stack = std.ArrayList([2]Vec2).init(allocator);
    defer stack.deinit();
    for (directions) |dir| {
        try stack.append(.{ end, dir });
    }

    while (stack.items.len > 0) {
        const node = stack.pop();
        if (visited.contains(node)) {
            continue;
        }

        try visited.put(node, {});
        try seats.put(node[0], {});

        if (prev.get(node)) |list| {
            for (list.items) |v| {
                try stack.append(v);
            }
        }
    }

    return seats.keys().len;
}

fn dijkstra(allocator: std.mem.Allocator, maze: [][]const u8, start: Vec2, end: Vec2) !struct {
    dist: std.AutoArrayHashMap([2]Vec2, i64),
    prev: std.AutoArrayHashMap([2]Vec2, std.ArrayList([2]Vec2)),
} {
    var dist = std.AutoArrayHashMap([2]Vec2, i64).init(allocator);
    try dist.put(.{ start, Vec2{ 1, 0 } }, 0);

    var q = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer q.deinit();
    try q.add(.{ .pos = start, .score = 0, .dir = Vec2{ 1, 0 } });

    var prev = std.AutoArrayHashMap([2]Vec2, std.ArrayList([2]Vec2)).init(allocator);

    var cost: i64 = std.math.maxInt(i64);
    while (q.count() != 0) {
        const u = q.remove();
        if (u.score > cost) break;
        if (std.meta.eql(u.pos, end)) cost = u.score;

        // for each neighbor v of u
        for (directions) |dir| {
            if (std.meta.eql(dir, Vec2{ -1, -1 } * u.dir)) {
                continue;
            }
            const v = u.pos + dir;
            if (maze[@intCast(v[1])][@intCast(v[0])] == '#') {
                continue;
            }

            const alt = dist.get(.{ u.pos, u.dir }).? + turnScore(u.dir, dir);

            if (alt <= (dist.get(.{ v, dir }) orelse std.math.maxInt(i64))) {
                try dist.put(.{ v, dir }, alt);

                var prevs = prev.get(.{ v, dir }) orelse std.ArrayList([2]Vec2).init(allocator);
                try prevs.append(.{ u.pos, u.dir });
                try prev.put(.{ v, dir }, prevs);

                try q.add(.{ .pos = v, .score = alt, .dir = dir });
            }
        }
    }

    return .{ .dist = dist, .prev = prev };
}

fn turnScore(dir: Vec2, last_dir: Vec2) i64 {
    if (!std.meta.eql(dir, last_dir)) {
        return 1001;
    } else {
        return 1;
    }
}
