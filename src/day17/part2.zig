const std = @import("std");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    const a = try ctx.computer.findA();

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{a});
}
