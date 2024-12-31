const std = @import("std");
const d2p1 = @import("part1.zig");
const Context = d2p1.Context;

pub fn part2(ctx: Context) ![]const u8 {
    const allocator = ctx.allocator;
    var sum: u64 = 0;
    for (ctx.reports) |levels| {
        if (d2p1.isIncreasingSafely(levels) or d2p1.isDecreasingSafely(levels)) {
            sum += 1;
        } else {
            for (0..levels.len) |i| {
                var new_levels = std.ArrayList(u64).init(allocator);
                for (levels, 0..) |level, j| {
                    if (j == i) continue;
                    try new_levels.append(level);
                }
                const dampened = try new_levels.toOwnedSlice();
                defer allocator.free(dampened);
                if (d2p1.isIncreasingSafely(dampened) or d2p1.isDecreasingSafely(dampened)) {
                    sum += 1;
                    break;
                }
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
