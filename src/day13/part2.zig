const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;

pub fn part2(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.machines) |*m| {
        m.prize[0] += 10_000_000_000_000;
        m.prize[1] += 10_000_000_000_000;
        sum += m.prizeMoves() catch continue;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
