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

pub const Context = struct {
    allocator: std.mem.Allocator,
    array: [][]const u8,
    map: std.AutoArrayHashMap([2]usize, u8),
};

pub fn parse(allocator: std.mem.Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    var lines = std.mem.tokenizeSequence(u8, in, "\n");
    var array_acc = std.ArrayList([]const u8).init(allocator);
    defer array_acc.deinit();
    var map = std.AutoArrayHashMap([2]usize, u8).init(allocator);

    var row: usize = 0;

    while (lines.next()) |line| {
        try array_acc.append(line);

        for (line, 0..) |char, col| {
            try map.put(.{ row, col }, char);
        }
        row += 1;
    }

    ctx.array = try array_acc.toOwnedSlice();
    ctx.map = map;
    ctx.allocator = allocator;

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.array, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'X') {
                sum += searchForXmas(ctx.array, row, col);
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn searchForXmas(array: [][]const u8, row: usize, col: usize) u64 {
    const row_as = @as(i64, @intCast(row));
    const col_as = @as(i64, @intCast(col));
    var sum: u64 = 0;
    for (directions) |dir| {
        // search for M at dir
        if (searchForChar(array, row, col, 'M', dir) and
            searchForChar(array, @as(usize, @intCast(row_as + dir[0])), @as(usize, @intCast(col_as + dir[1])), 'A', dir) and
            searchForChar(array, @as(usize, @intCast(row_as + dir[0] * 2)), @as(usize, @intCast(col_as + dir[1] * 2)), 'S', dir))
        {
            sum += 1;
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
