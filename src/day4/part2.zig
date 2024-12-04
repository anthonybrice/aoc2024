const std = @import("std");
const util = @import("../main.zig");

const directions = [_][2]i64{
    .{ -1, -1 }, // up-left
    .{ -1, 1 }, // up-right
    .{ 1, -1 }, // down-left
    .{ 1, 1 }, // down-right
};

const checks = [_][2]i64{
    .{ 2, 0 }, // right
    .{ 0, 2 }, // down
};

const Elem = struct {
    char: u8,
    up_left: bool,
    up_right: bool,
    down_left: bool,
    down_right: bool,
};

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var map = std.AutoArrayHashMap([2]usize, Elem).init(allocator);
    defer map.deinit();

    var row: usize = 0;
    var line_len: usize = 0;
    while (lines.next()) |line| {
        line_len = line.len;
        for (line, 0..) |char, col| {
            try map.put(.{ row, col }, Elem{
                .char = char,
                .up_left = false,
                .up_right = false,
                .down_left = false,
                .down_right = false,
            });
        }
        row += 1;
    }

    for (0..row - 1) |i| {
        for (0..line_len - 1) |j| {
            const elem: Elem = map.get(.{ i, j }).?;
            if (elem.char == 'M') {
                _ = isXmas(&map, i, j);
            }
        }
    }
}

fn isXmas(map: *std.AutoArrayHashMap([2]usize, Elem), row: usize, col: usize) bool {
    _ = map;
    _ = row;
    _ = col;
    // for every unvisited direction, check if the next two characters are A and S
    // if so, check right and down for an M
    // If so, check cross-direction for an S
    // if so, mark satisfied directions as visited and return true

    // or grab every relevant cell, check, and if so, mark dirs as visited?

    return false;
}
