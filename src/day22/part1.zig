const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');

    var sum: u64 = 0;
    while (lines.next()) |line| {
        var n = try std.fmt.parseInt(u64, line, 10);
        for (0..2000) |_| {
            n = nextSecretNumber(n);
        }
        sum += n;
    }
    std.debug.print("{d}\n", .{sum});
}

fn nextSecretNumber(n: u64) u64 {
    const n1 = n * 64;
    const n2 = n1 ^ n;
    const n3 = n2 % 16777216;
    const n4 = n3 / 32;
    const n5 = n4 ^ n3;
    const n6 = n5 % 16777216;
    const n7 = n6 * 2048;
    const n8 = n7 ^ n6;
    const n9 = n8 % 16777216;

    return n9;
}
