const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var antenna_map = std.AutoArrayHashMap(u8, std.ArrayList([2]usize)).init(allocator);
    defer {
        for (antenna_map.values()) |list| list.deinit();
        antenna_map.deinit();
    }
    var row: usize = 0;
    var cols: usize = undefined;
    while (lines.next()) |line| {
        cols = line.len;
        for (line, 0..) |char, col| {
            if (std.ascii.isDigit(char) or std.ascii.isAlphabetic(char)) {
                var list =
                    antenna_map.get(char) orelse std.ArrayList([2]usize).init(allocator);
                try list.append([2]usize{ row, col });
                try antenna_map.put(char, list);
            }
        }
        row += 1;
    }
    const rows = row;

    var antinodes = std.AutoArrayHashMap([2]usize, void).init(allocator);
    defer antinodes.deinit();
    for (0..rows) |i| {
        for (0..cols) |j| {
            for (antenna_map.keys()) |char| {
                for (antenna_map.get(char).?.items) |this| {
                    for (antenna_map.get(char).?.items) |other| {
                        if (std.mem.eql(usize, &this, &other)) continue;
                        const curr_i64 = [2]i64{ @intCast(i), @intCast(j) };
                        const this_i64 = [2]i64{ @intCast(this[0]), @intCast(this[1]) };
                        const other_i64 = [2]i64{ @intCast(other[0]), @intCast(other[1]) };
                        if (areCollinear(
                            curr_i64,
                            this_i64,
                            other_i64,
                        )) {
                            try antinodes.put([2]usize{ i, j }, {});
                        }
                    }
                }
            }
        }
    }
    std.debug.print("{d}\n", .{antinodes.keys().len});
}

fn areCollinear(p1: [2]i64, p2: [2]i64, p3: [2]i64) bool {
    const x1 = p1[0];
    const y1 = p1[1];
    const x2 = p2[0];
    const y2 = p2[1];
    const x3 = p3[0];
    const y3 = p3[1];

    return (y2 - y1) * (x3 - x2) == (y3 - y2) * (x2 - x1);
}

fn calculateManhattanDistance(p1: [2]i64, p2: [2]i64) u64 {
    return @abs(p2[0] - p1[0]) + @abs(p2[1] - p1[1]);
}
