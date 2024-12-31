const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    memory: std.AutoArrayHashMap(Vec2, u8),
    lines: std.mem.TokenIterator(u8, .scalar),
    path: ?std.AutoArrayHashMap(Vec2, void),

    pub fn deinit(self: *Context) void {
        self.memory.deinit();
        if (self.path != null) self.path.?.deinit();
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.memory = std.AutoArrayHashMap(Vec2, u8).init(allocator);

    for (0..71) |i| {
        for (0..71) |j| {
            try ctx.memory.put(Vec2{ @intCast(i), @intCast(j) }, '.');
        }
    }

    var lines = std.mem.tokenizeScalar(u8, in, '\n');

    for (0..1024) |_| {
        const line = lines.next().?;
        var tokens = std.mem.tokenizeScalar(u8, line, ',');
        const y = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const x = try std.fmt.parseInt(i64, tokens.next().?, 10);
        try ctx.memory.put(Vec2{ x, y }, '#');
    }

    ctx.lines = lines;
    ctx.path = null;

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const path = try aStar(ctx.allocator, ctx.memory, Vec2{ 0, 0 }, Vec2{ 70, 70 });
    ctx.path = path;

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{path.keys().len - 1});
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

pub fn aStar(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2, goal: Vec2) !std.AutoArrayHashMap(Vec2, void) {
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

fn reconstructPath(allocator: std.mem.Allocator, cameFrom: std.AutoArrayHashMap(Vec2, Vec2), current: Vec2) !std.AutoArrayHashMap(Vec2, void) {
    var totalPath = std.AutoArrayHashMap(Vec2, void).init(allocator);

    try totalPath.put(current, {});
    var curr = current;
    while (cameFrom.contains(curr)) {
        curr = cameFrom.get(curr).?;
        try totalPath.put(curr, {});
    }

    return totalPath;
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
