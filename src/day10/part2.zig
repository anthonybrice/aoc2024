const std = @import("std");
const Context = @import("part1.zig").Context;

pub fn part2(ctx: Context) ![]const u8 {
    const row = ctx.dims[0];
    const col = ctx.dims[1];

    var sum: u64 = 0;
    for (0..row) |i| {
        for (0..col) |j| {
            if (ctx.height_map.get(.{ i, j }) == 0) {
                sum += try find_trail(ctx.allocator, ctx.height_map, i, j);
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

fn find_trail(
    allocator: std.mem.Allocator,
    height_map: anytype,
    i: usize,
    j: usize,
) !usize {
    var stack = std.ArrayList([2]usize).init(allocator);
    defer stack.deinit();
    try stack.append(.{ i, j });

    var nines: u64 = 0;
    while (stack.items.len > 0) {
        const pos = stack.pop();
        const current_value = height_map.get(pos).?;

        if (current_value == 9) {
            nines += 1;
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

    return nines;
}
