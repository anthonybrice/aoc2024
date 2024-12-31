const std = @import("std");
const p1 = @import("part1.zig");
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    var start: usize = 1024;
    while (true) {
        const line = ctx.lines.next().?;
        var tokens = std.mem.tokenizeScalar(u8, line, ',');
        const y = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const x = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const key = Vec2{ x, y };
        try ctx.memory.put(key, '#');
        if (!ctx.path.?.contains(key)) continue;

        const path = p1.aStar(
            ctx.allocator,
            ctx.memory,
            Vec2{ 0, 0 },
            Vec2{ 70, 70 },
        ) catch |err| switch (err) {
            error.PathNotFound => {
                return std.fmt.allocPrint(ctx.allocator, "{d},{d}", .{ y, x });
            },
            else => return error.Unexpected,
        };
        ctx.path.?.deinit();
        ctx.path = path;
        start += 1;
    }
}
