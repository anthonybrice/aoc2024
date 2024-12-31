const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: std.mem.Allocator,
    map: std.AutoHashMap(Vec2, u8),
    path: std.ArrayList(struct {
        Vec2,
        u8,
    }),
    start_idx: Vec2,

    pub fn deinit(self: *Context) void {
        self.map.deinit();
        self.path.deinit();
    }
};

pub fn parse(allocator: std.mem.Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    const file_contents = in;

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var map = std.AutoHashMap(Vec2, u8).init(allocator);
    const path = std.ArrayList(struct {
        Vec2,
        u8,
    }).init(allocator);

    var row: usize = 0;
    while (lines.next()) |line| {
        for (line, 0..) |char, col| {
            try map.put(.{ @intCast(row), @intCast(col) }, char);
            if (char == '^' or char == 'v' or char == '<' or char == '>') {
                ctx.start_idx = .{ @intCast(row), @intCast(col) };
            }
        }
        row += 1;
    }

    ctx.map = map;
    ctx.allocator = allocator;
    ctx.path = path;

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var curr_dir = ctx.map.get(ctx.start_idx).?;
    var curr_idx = ctx.start_idx;
    var visited = std.AutoArrayHashMap(Vec2, void).init(ctx.allocator);
    while (true) {
        try visited.put(curr_idx, {});
        try ctx.path.append(.{ curr_idx, curr_dir });
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
        const next_char = ctx.map.get(next_idx) orelse break;
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

    const sum: u64 = visited.keys().len;

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
