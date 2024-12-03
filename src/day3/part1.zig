const std = @import("std");
const util = @import("../main.zig");
const mvzr = @import("../mvzr.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    const mul_regex = mvzr.compile("mul\\((\\d+),(\\d+)\\)").?;
    var mul_iter = mul_regex.iterator(file_contents);

    var sum: u64 = 0;
    while (mul_iter.next()) |match| {
        const instruction = match.slice;

        const int_regex = mvzr.compile("\\d+").?;
        var int_iter = int_regex.iterator(instruction);
        const int1 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);
        const int2 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);

        sum += int1 * int2;
    }

    std.debug.print("{d}\n", .{sum});
}
