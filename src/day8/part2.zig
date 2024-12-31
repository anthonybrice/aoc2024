const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;
const util = @import("../main.zig");

pub fn part2(ctx: *Context) ![]const u8 {
    const rows = ctx.dims[0];
    const cols = ctx.dims[1];
    const antenna_map = &ctx.antenna_map;
    var antinodes = std.AutoArrayHashMap([2]usize, void).init(ctx.allocator);
    defer antinodes.deinit();

    for (0..rows) |i| {
        for (0..cols) |j| {
            for (antenna_map.keys()) |char| {
                for (antenna_map.get(char).?.items) |this| {
                    for (antenna_map.get(char).?.items) |other| {
                        if (std.meta.eql(this, other)) continue;

                        const curr_i64 = [2]i64{ @intCast(i), @intCast(j) };
                        const this_i64 = [2]i64{ @intCast(this[0]), @intCast(this[1]) };
                        const other_i64 = [2]i64{ @intCast(other[0]), @intCast(other[1]) };
                        if (areCollinear(
                            curr_i64,
                            this_i64,
                            other_i64,
                        )) {
                            try antinodes.put([2]usize{ i, j }, {});
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

fn calculateManhattanDistance(p1: [2]i64, p2: [2]i64) u64 {
    return @abs(p2[0] - p1[0]) + @abs(p2[1] - p1[1]);
}
