const std = @import("std");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    var memo = std.StringHashMap(u64).init(ctx.allocator);
    defer memo.deinit();

    var sum: u64 = 0;
    for (ctx.towels) |towel| {
        const ways = try countWays(
            towel,
            ctx.towel_patterns,
            &memo,
        );
        sum += ways;
    }

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn countWays(
    towel: []const u8,
    towel_patterns: []const []const u8,
    memo: *std.StringHashMap(u64),
) !u64 {
    if (towel.len == 0) {
        return 1;
    }

    if (memo.get(towel)) |result| {
        return result;
    }

    var total_ways: u64 = 0;
    for (towel_patterns) |pattern| {
        if (std.mem.startsWith(u8, towel, pattern)) {
            const remaining_towel = towel[pattern.len..];
            total_ways += try countWays(remaining_towel, towel_patterns, memo);
        }
    }

    try memo.put(towel, total_ways);
    return total_ways;
}
