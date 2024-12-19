const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    const towel_patterns = try parseAvailablePatterns(allocator, lines.next().?);
    defer allocator.free(towel_patterns);

    var memo = std.StringHashMap(u64).init(allocator);
    defer memo.deinit();

    var sum: u64 = 0;
    while (lines.next()) |towel| {
        const ways = try countWays(
            towel,
            towel_patterns,
            &memo,
        );
        sum += ways;
    }

    std.debug.print("{d}\n", .{sum});
}

fn parseAvailablePatterns(allocator: std.mem.Allocator, in: []const u8) ![]const []const u8 {
    var tokens = std.mem.tokenizeSequence(u8, in, ", ");
    var towel_patterns = std.ArrayList([]const u8).init(allocator);
    defer towel_patterns.deinit();

    while (tokens.next()) |token| {
        try towel_patterns.append(token);
    }

    return towel_patterns.toOwnedSlice();
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
