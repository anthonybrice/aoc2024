const std = @import("std");
const Context = @import("part1.zig").Context;

pub fn part2(ctx: Context) ![]const u8 {
    var right_counts = std.AutoHashMap(i64, i64).init(ctx.allocator);
    defer right_counts.deinit();
    for (ctx.right) |n| {
        if (right_counts.get(n)) |count| {
            try right_counts.put(n, count + 1);
        } else {
            try right_counts.put(n, 1);
        }
    }

    var sum: i64 = 0;
    for (ctx.left) |left| {
        const count = right_counts.get(left) orelse 0;
        sum += left * count;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
