const std = @import("std");
const d2p1 = @import("part1.zig");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var reports = std.mem.tokenizeSequence(u8, file_contents, "\n");

    var sum: u64 = 0;
    while (reports.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        var levels = std.ArrayList(u64).init(allocator);

        while (tokens.next()) |token| {
            const level = try std.fmt.parseInt(u64, token, 10);
            try levels.append(level);
        }

        const levels_slice = try levels.toOwnedSlice();
        defer allocator.free(levels_slice);

        if (d2p1.isIncreasingSafely(levels_slice) or d2p1.isDecreasingSafely(levels_slice)) {
            sum += 1;
        } else {
            for (0..levels_slice.len) |i| {
                var new_levels = std.ArrayList(u64).init(allocator);
                for (levels_slice, 0..levels_slice.len) |level, j| {
                    if (j == i) continue;
                    try new_levels.append(level);
                }
                const levels_slice_dampened = try new_levels.toOwnedSlice();
                defer allocator.free(levels_slice_dampened);
                if (d2p1.isIncreasingSafely(levels_slice_dampened) or d2p1.isDecreasingSafely(levels_slice_dampened)) {
                    sum += 1;
                    break;
                }
            }
        }
    }

    std.debug.print("{d}\n", .{sum});
}
