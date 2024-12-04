const std = @import("std");
const util = @import("../main.zig");

const directions = [_][2]i64{
    .{ -1, 0 }, // up
    .{ 1, 0 }, // down
    .{ 0, -1 }, // left
    .{ 0, 1 }, // right
    .{ -1, -1 }, // up-left
    .{ -1, 1 }, // up-right
    .{ 1, -1 }, // down-left
    .{ 1, 1 }, // down-right
};

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var array_acc = std.ArrayList([]const u8).init(allocator);
    while (lines.next()) |line| try array_acc.append(line);
    const array = try array_acc.toOwnedSlice();
    defer allocator.free(array);

    var sum: u64 = 0;
    for (array, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'X') {
                sum += searchForXmas(array, row, col);
            }
        }
    }

    std.debug.print("{d}\n", .{sum});
}

fn searchForXmas(array: [][]const u8, row: usize, col: usize) u64 {
    const row_as = @as(i64, @intCast(row));
    const col_as = @as(i64, @intCast(col));
    var sum: u64 = 0;
    for (directions) |dir| {
        // search for M at dir
        if (searchForChar(array, row, col, 'M', dir)) {
            // search for A at dir
            if (searchForChar(array, @as(usize, @intCast(row_as + dir[0])), @as(usize, @intCast(col_as + dir[1])), 'A', dir)) {
                // search for S at dir
                if (searchForChar(array, @as(usize, @intCast(row_as + dir[0] * 2)), @as(usize, @intCast(col_as + dir[1] * 2)), 'S', dir)) {
                    sum += 1;
                }
            }
        }
    }

    return sum;
}

fn searchForChar(array: [][]const u8, row: usize, col: usize, char: u8, dir: [2]i64) bool {
    const idx: [2]i64 = .{ @as(i64, @intCast(row)) + dir[0], @as(i64, @intCast(col)) + dir[1] };
    const array_len = @as(i64, @intCast(array.len));
    const line_len = @as(i64, @intCast(array[row].len));

    const bounded = idx[0] >= 0 and idx[0] < array_len and idx[1] >= 0 and idx[1] < line_len;
    if (!bounded) return false;
    const is_char = array[@as(usize, @intCast(idx[0]))][@as(usize, @intCast(idx[1]))] == char;
    return bounded and is_char;
}
