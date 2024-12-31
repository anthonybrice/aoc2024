const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    maze: [][]const u8,

    pub fn deinit(self: *Context) void {
        for (self.maze) |line| {
            self.allocator.free(line);
        }
        self.allocator.free(self.maze);
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;

    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var maze = std.ArrayList([]u8).init(allocator);

    while (lines.next()) |line| {
        var new_line = std.ArrayList(u8).init(allocator);
        for (line) |char| {
            try new_line.append(char);
        }
        try maze.append(try new_line.toOwnedSlice());
    }

    ctx.maze = try maze.toOwnedSlice();

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const start = findReindeer(ctx.maze);
    const end = findEnd(ctx.maze);

    const path = try aStar(ctx.allocator, ctx.maze, start.pos, end);
    defer ctx.allocator.free(path);

    var turns: u64 = 0;
    var steps: u64 = 0;
    var last_dir = Vec2{ 1, 0 };

    var i = path.len - 1;
    while (i > 0) {
        i -= 1;
        const pos = path[i];
        const dir = pos - path[i + 1];
        if (std.meta.eql(dir, last_dir)) {
            steps += 1;
        } else {
            turns += 1;
            steps += 1;
            last_dir = dir;
        }
    }

    const score = 1000 * turns + steps;

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{score});
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

fn heuristic(a: Vec2, b: Vec2) i64 {
    const x: i64 = @intCast(@abs(a[0] - b[0]));
    const y: i64 = @intCast(@abs(a[1] - b[1]));
    return x + y;
}

const PqItem = struct {
    pos: Vec2,
    score: i64,
};

fn lessThan(context: void, a: PqItem, b: PqItem) std.math.Order {
    _ = context;
    return std.math.order(a.score, b.score);
}

pub fn aStar(allocator: std.mem.Allocator, maze: [][]const u8, start: Vec2, goal: Vec2) ![]Vec2 {
    const directions = [_]Vec2{
        Vec2{ -1, 0 },
        Vec2{ 1, 0 },
        Vec2{ 0, -1 },
        Vec2{ 0, 1 },
    };

    var open_set = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer open_set.deinit();
    try open_set.add(.{ .pos = start, .score = 0 });

    var came_from = std.AutoArrayHashMap(Vec2, [2]Vec2).init(allocator);
    defer came_from.deinit();

    var g_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    var f_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer f_score.deinit();
    try f_score.put(start, heuristic(start, goal));

    var curr_dir = Vec2{ 1, 0 };

    while (open_set.count() != 0) {
        const current = open_set.remove();

        if (std.meta.eql(current.pos, goal)) {
            return reconstructPath(allocator, came_from, current.pos);
        }

        for (directions) |dir| {
            const neighbor = current.pos + dir;
            if (maze[@intCast(neighbor[1])][@intCast(neighbor[0])] == '#') {
                continue;
            }

            if (came_from.contains(current.pos)) {
                curr_dir = came_from.get(current.pos).?[1];
            }

            var tentative_g_score: i64 = 0;
            if (std.meta.eql(curr_dir, dir)) {
                tentative_g_score = g_score.get(current.pos).? + 1;
            } else {
                // Since we start in the lower-left corner and face east,
                // we never need to consider the case of turning 180 degrees from the start.
                tentative_g_score = g_score.get(current.pos).? + 1001;
            }

            if (tentative_g_score < (g_score.get(neighbor) orelse std.math.maxInt(i64))) {
                try came_from.put(neighbor, .{ current.pos, dir });
                try g_score.put(neighbor, tentative_g_score);
                try f_score.put(neighbor, tentative_g_score + heuristic(neighbor, goal));
                try open_set.add(.{ .pos = neighbor, .score = tentative_g_score + heuristic(neighbor, goal) });
            }
        }
    }

    return error.PathNotFound;
}

fn reconstructPath(allocator: std.mem.Allocator, cameFrom: std.AutoArrayHashMap(Vec2, [2]Vec2), current: Vec2) ![]Vec2 {
    var totalPath = std.ArrayList(Vec2).init(allocator);
    defer totalPath.deinit();

    try totalPath.append(current);
    var curr = current;
    while (cameFrom.contains(curr)) {
        curr = cameFrom.get(curr).?[0];
        try totalPath.append(curr);
    }

    return totalPath.toOwnedSlice();
}

pub fn printMazeWithPath(allocator: std.mem.Allocator, maze: [][]const u8, path: []Vec2) !void {
    var maze_copy_list = std.ArrayList([]u8).init(allocator);
    for (maze) |line| {
        var line_copy = std.ArrayList(u8).init(allocator);
        for (line) |char| {
            try line_copy.append(char);
        }
        try maze_copy_list.append(try line_copy.toOwnedSlice());
    }
    const maze_copy = try maze_copy_list.toOwnedSlice();
    defer {
        for (maze_copy) |line| {
            allocator.free(line);
        }
        allocator.free(maze_copy);
    }

    for (path[1..], 0..) |pos, i| {
        const prev_pos = path[i];
        const dir = pos - prev_pos;
        const x: usize = @intCast(pos[0]);
        const y: usize = @intCast(pos[1]);

        var arrow: u8 = undefined;
        if (std.meta.eql(dir, Vec2{ -1, 0 })) {
            arrow = '>';
        } else if (std.meta.eql(dir, Vec2{ 1, 0 })) {
            arrow = '<';
        } else if (std.meta.eql(dir, Vec2{ 0, -1 })) {
            arrow = 'v';
        } else if (std.meta.eql(dir, Vec2{ 0, 1 })) {
            arrow = '^';
        }

        if (maze_copy[y][x] != 'S' and maze_copy[y][x] != 'E') {
            maze_copy[y][x] = arrow;
        }
    }

    for (maze_copy) |line| {
        std.debug.print("{s}\n", .{line});
    }
}
