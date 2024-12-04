const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var map = std.AutoArrayHashMap([2]usize, u8).init(allocator);
    defer map.deinit();

    var row: usize = 0;
    var line_len: usize = 0;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |char, col| {
            try map.put(.{ row, col }, char);
        }
        row += 1;
    }

    var iter = map.iterator();
    var sum: u64 = 0;
    while (iter.next()) |entry| {
        const key = entry.key_ptr;
        if (try isXmas(allocator, map, key[0], key[1])) sum += 1;
    }

    std.debug.print("{d}\n", .{sum});
}

fn isXmas(
    allocator: std.mem.Allocator,
    map: std.AutoArrayHashMap([2]usize, u8),
    row: usize,
    col: usize,
) !bool {
    if (row == 0 or col == 0) return false;
    const a = map.get(.{ row, col }) orelse return false;
    if (a != 'A') return false;

    const above_left = map.get(.{ row - 1, col - 1 }) orelse return false;
    const above_right = map.get(.{ row - 1, col + 1 }) orelse return false;
    const below_left = map.get(.{ row + 1, col - 1 }) orelse return false;
    const below_right = map.get(.{ row + 1, col + 1 }) orelse return false;

    const arr = try std.fmt.allocPrint(
        allocator,
        "{c}{c}{c}{c}",
        .{ above_left, above_right, below_left, below_right },
    );
    defer allocator.free(arr);

    if (std.mem.eql(u8, arr, "MMSS") or
        std.mem.eql(u8, arr, "SSMM") or
        std.mem.eql(u8, arr, "MSMS") or
        std.mem.eql(u8, arr, "SMSM"))
    {
        return true;
    }

    return false;
}
