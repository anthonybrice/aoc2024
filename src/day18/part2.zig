const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    var memory = std.AutoArrayHashMap(Vec2, u8).init(allocator);
    defer memory.deinit();

    for (0..71) |i| {
        const ip: i64 = @intCast(i);
        for (0..71) |j| {
            const jp: i64 = @intCast(j);
            try memory.put(Vec2{ ip, jp }, '.');
        }
    }

    for (0..1024) |_| {
        const line = lines.next().?;
        var tokens = std.mem.tokenizeScalar(u8, line, ',');
        const y = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const x = try std.fmt.parseInt(i64, tokens.next().?, 10);
        try memory.put(Vec2{ x, y }, '#');
    }

    var x: i64 = undefined;
    var y: i64 = undefined;
    var start: usize = 1024;
    while (true) {
        const line = lines.next().?;
        var tokens = std.mem.tokenizeScalar(u8, line, ',');
        y = try std.fmt.parseInt(i64, tokens.next().?, 10);
        x = try std.fmt.parseInt(i64, tokens.next().?, 10);
        try memory.put(Vec2{ x, y }, '#');

        const path = aStar(
            allocator,
            memory,
            Vec2{ 0, 0 },
            Vec2{ 70, 70 },
        ) catch |err| switch (err) {
            error.PathNotFound => {
                std.debug.print("{d},{d}\n", .{ y, x });
                break;
            },
            else => return error.Unexpected,
        };
        allocator.free(path);
        start += 1;
    }

    // std.debug.print("{d}\n", .{path.len - 1});
}

fn heuristic(a: Vec2, b: Vec2) i64 {
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
    try open_set.add(.{ .pos = start, .f_score = heuristic(start, goal) });

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
                try open_set.add(.{ .pos = neighbor, .f_score = tentative_g_score + heuristic(neighbor, goal) });
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

fn printMaze(memory: std.AutoArrayHashMap(Vec2, u8)) void {
    const width = 71;
    const height = 71;

    for (0..height) |i| {
        for (0..width) |j| {
            const pos = Vec2{ @intCast(i), @intCast(j) };
            const cell = memory.get(pos) orelse '.';
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}
