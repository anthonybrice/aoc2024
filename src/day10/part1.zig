const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    height_map: std.AutoArrayHashMap([2]usize, u8),
    dims: [2]usize,

    pub fn deinit(self: *Context) void {
        self.height_map.deinit();
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.height_map = std.AutoArrayHashMap([2]usize, u8).init(allocator);

    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var row: usize = 0;
    var line_len: usize = undefined;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |char, col| {
            try ctx.height_map.put(.{ row, col }, char - '0');
        }
        row += 1;
    }

    ctx.dims = .{ row, line_len };

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (0..ctx.height_map.keys().len) |i| {
        for (0..ctx.height_map.keys().len) |j| {
            if (ctx.height_map.get(.{ i, j }) == 0) {
                sum += try findTrail(ctx.allocator, ctx.height_map, i, j);
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

const directions = [_][2]i64{
    .{ -1, 0 }, // up
    .{ 1, 0 }, // down
    .{ 0, -1 }, // left
    .{ 0, 1 }, // right
};

fn findTrail(
    allocator: std.mem.Allocator,
    height_map: anytype,
    i: usize,
    j: usize,
) !usize {
    var stack = std.ArrayList([2]usize).init(allocator);
    defer stack.deinit();
    try stack.append(.{ i, j });

    var nines = std.AutoArrayHashMap([2]usize, void).init(allocator);
    defer nines.deinit();
    while (stack.items.len > 0) {
        const pos = stack.pop();
        const current_value = height_map.get(pos).?;

        if (current_value == 9) {
            try nines.put(pos, {});
            continue;
        }

        for (directions) |dir| {
            const new_i = @as(i64, @intCast(pos[0])) + dir[0];
            const new_j = @as(i64, @intCast(pos[1])) + dir[1];
            if (new_i < 0 or new_j < 0) continue;

            const next_value = height_map.get(.{ @intCast(new_i), @intCast(new_j) }) orelse continue;
            if (next_value == current_value + 1) {
                try stack.append(.{ @intCast(new_i), @intCast(new_j) });
            }
        }
    }

    return nines.keys().len;
}
