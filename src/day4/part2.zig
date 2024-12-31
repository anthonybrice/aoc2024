const std = @import("std");
const Context = @import("part1.zig").Context;

pub fn part2(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    var iter = ctx.map.iterator();
    while (iter.next()) |entry| {
        const key = entry.key_ptr;
        if (isXmas(ctx.map, key[0], key[1])) sum += 1;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn isXmas(
    map: anytype,
    row: usize,
    col: usize,
) bool {
    if (row == 0 or col == 0) return false;
    const a = map.get(.{ row, col }) orelse return false;
    if (a != 'A') return false;

    const above_left = map.get(.{ row - 1, col - 1 }) orelse return false;
    const above_right = map.get(.{ row - 1, col + 1 }) orelse return false;
    const below_left = map.get(.{ row + 1, col - 1 }) orelse return false;
    const below_right = map.get(.{ row + 1, col + 1 }) orelse return false;

    const arr = .{ above_left, above_right, below_left, below_right };

    if (std.mem.eql(u8, &arr, "MMSS") or
        std.mem.eql(u8, &arr, "SSMM") or
        std.mem.eql(u8, &arr, "MSMS") or
        std.mem.eql(u8, &arr, "SMSM"))
    {
        return true;
    }

    return false;
}
