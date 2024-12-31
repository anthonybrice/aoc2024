const std = @import("std");
const Context = @import("part2.zig").Context;
const p2 = @import("part2.zig");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: i64 = 0;
    for (ctx.init_ns) |n| {
        var curr = n;
        for (0..2000) |_| {
            curr = p2.nextSecretNumber(curr);
        }
        sum += curr;
    }

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
