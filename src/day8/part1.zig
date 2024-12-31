const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../main.zig");

const Vec2 = @Vector(2, usize);

pub const Context = struct {
    allocator: Allocator,
    antenna_map: std.AutoArrayHashMap(u8, std.ArrayList(Vec2)),
    dims: Vec2,

    pub fn deinit(self: *Context) void {
        self.antenna_map.deinit();
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.antenna_map = std.AutoArrayHashMap(u8, std.ArrayList(Vec2)).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var row: usize = 0;
    var cols: usize = undefined;
    while (lines.next()) |line| {
        cols = line.len;
        for (line, 0..) |char, col| {
            if (std.ascii.isDigit(char) or std.ascii.isAlphabetic(char)) {
                var list =
                    ctx.antenna_map.get(char) orelse std.ArrayList(Vec2).init(allocator);
                try list.append(Vec2{ row, col });
                try ctx.antenna_map.put(char, list);
            }
        }
        row += 1;
    }

    ctx.dims = Vec2{ row, cols };

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const rows = ctx.dims[0];
    const cols = ctx.dims[1];
    var antinodes = std.AutoArrayHashMap(Vec2, void).init(ctx.allocator);
    defer antinodes.deinit();
    for (0..rows) |i| {
        for (0..cols) |j| {
            for (ctx.antenna_map.keys()) |char| {
                for (ctx.antenna_map.get(char).?.items) |this| {
                    for (ctx.antenna_map.get(char).?.items) |other| {
                        if (std.meta.eql(this, other)) continue;

                        const curr_i64 = [2]i64{ @intCast(i), @intCast(j) };
                        const this_i64 = [2]i64{ @intCast(this[0]), @intCast(this[1]) };
                        const other_i64 = [2]i64{ @intCast(other[0]), @intCast(other[1]) };
                        const d_this = manhattanDistance(curr_i64, this_i64);
                        const d_other = manhattanDistance(curr_i64, other_i64);
                        if (areCollinear(
                            curr_i64,
                            this_i64,
                            other_i64,
                        ) and ((d_this == d_other * 2) or (2 * d_this == d_other))) {
                            try antinodes.put(.{ i, j }, {});
                            break;
                        }
                    }
                    if (antinodes.contains(.{ i, j })) break;
                }
                if (antinodes.contains(.{ i, j })) break;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{antinodes.keys().len});
}

fn areCollinear(p1: [2]i64, p2: [2]i64, p3: [2]i64) bool {
    const x1 = p1[0];
    const y1 = p1[1];
    const x2 = p2[0];
    const y2 = p2[1];
    const x3 = p3[0];
    const y3 = p3[1];

    return (y2 - y1) * (x3 - x2) == (y3 - y2) * (x2 - x1);
}

fn manhattanDistance(p1: [2]i64, p2: [2]i64) u64 {
    return @abs(p2[0] - p1[0]) + @abs(p2[1] - p1[1]);
}
