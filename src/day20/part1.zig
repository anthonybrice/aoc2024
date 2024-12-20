const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    var maze = std.AutoArrayHashMap(Vec2, u8).init(allocator);
    defer maze.deinit();

    var row: i64 = 0;
    var cols: i64 = 0;
    while (lines.next()) |line| {
        cols = @intCast(line.len);
        var col: i64 = 0;
        for (line) |char| {
            const pos = .{ col, row };
            try maze.put(pos, char);
            col += 1;
        }
        row += 1;
    }

    // printMaze(maze, row, cols);

    const start = try findChar(maze, 'S');
    const end = try findChar(maze, 'E');

    const path = try aStar(allocator, maze, start, end);
    defer allocator.free(path);

    // Find all positions with a distance of 2 and a path length of 100 or more between them
    var poss_cheats = std.AutoArrayHashMap(Vec2, std.ArrayList(Vec2)).init(allocator);
    defer {
        var iter = poss_cheats.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        poss_cheats.deinit();
    }
    var cheat_times = std.AutoArrayHashMap(u64, u64).init(allocator);
    defer cheat_times.deinit();
    for (path, 101..) |pos1, i| {
        if (i >= path.len) {
            break;
        }
        for (path[i..]) |pos2| {
            const distance = manhattanDistance(pos1, pos2);
            if (distance == 2) {
                var l = poss_cheats.get(pos1) orelse std.ArrayList(Vec2).init(allocator);
                try l.append(pos2);
                try poss_cheats.put(pos1, l);
                const v = cheat_times.get(@intCast(i - 1)) orelse 0;
                try cheat_times.put(@intCast(i - 1), v + 1);
            }
        }
    }

    var iter = poss_cheats.iterator();
    var sum: usize = 0;
    while (iter.next()) |entry| {
        sum += entry.value_ptr.items.len;
    }
    std.debug.print("{d}\n", .{sum});

    // var cheats = std.AutoArrayHashMap(u64, u64).init(allocator);
    // for (1..@intCast(row - 1)) |i| {
    //     for (1..@intCast(cols - 1)) |j| {
    //         const pos: Vec2 = .{ @intCast(j), @intCast(i) };
    //         if (maze.get(pos).? == '#') {
    //             try maze.put(pos, '.');
    //             const new_path = try aStar(allocator, maze, start, end);
    //             const time_saved = path.len - new_path.len;
    //             const n = cheats.get(time_saved) orelse 0;
    //             try cheats.put(time_saved, n + 1);
    //             try maze.put(pos, '#');
    //         }
    //     }
    // }

    // var sum: u64 = 0;
    // var cheats_iter = cheats.iterator();
    // while (cheats_iter.next()) |entry| {
    //     if (entry.key_ptr.* >= 100) {
    //         sum += entry.value_ptr.*;
    //     }
    //     // std.debug.print("Time saved: {d}, Count: {d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    // }
    // std.debug.print("{d}\n", .{sum});
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
                try open_set.add(.{ .pos = neighbor, .f_score = tentative_g_score + manhattanDistance(neighbor, goal) });
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
