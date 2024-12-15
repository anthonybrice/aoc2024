const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var sections = std.mem.tokenizeSequence(u8, file_contents, "\n\n");

    const warehouse = try parseWarehouse(allocator, sections.next().?);
    defer {
        for (warehouse) |line| {
            allocator.free(line);
        }
        allocator.free(warehouse);
    }

    const moves = try parseMoves(allocator, sections.next().?);
    defer allocator.free(moves);

    var pos: Vec2 = undefined;
    for (warehouse, 0..) |line, row| {
        var atFound = false;
        var col: usize = 0;
        for (line) |char| {
            if (char == '@') {
                pos = Vec2{ @intCast(row), @intCast(col) };
                atFound = true;
                break;
            }
            col += 1;
        }
        if (atFound) {
            break;
        }
    }

    for (moves) |move| {
        pos = doMove(warehouse, pos, getDirection(move));
        // for (warehouse) |line| {
        //     std.debug.print("{s}\n", .{line});
        // }
        // std.debug.print("\n", .{});
    }

    var sum: usize = 0;
    for (warehouse, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'O') {
                sum += 100 * row + col;
            }
        }
    }

    std.debug.print("{d}\n", .{sum});
}

fn parseWarehouse(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var warehouse = std.ArrayList([]u8).init(allocator);

    while (lines.next()) |line| {
        const mut: []u8 = try allocator.alloc(u8, line.len);
        @memcpy(mut, line);
        try warehouse.append(mut);
    }

    return warehouse.toOwnedSlice();
}

fn parseMoves(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var moves = std.ArrayList(u8).init(allocator);

    while (lines.next()) |line| {
        try moves.appendSlice(line);
    }

    return moves.toOwnedSlice();
}

fn doMove(warehouse: [][]u8, pos: Vec2, move: Vec2) Vec2 {
    var new_pos = pos;
    if (!willCauseCollision(warehouse, pos, move)) {
        new_pos = pos + move;
        const x: usize = @intCast(new_pos[0]);
        const y: usize = @intCast(new_pos[1]);
        if (warehouse[x][y] == 'O') {
            // Shift the 'O' characters
            var curr = new_pos;
            while (warehouse[@intCast(curr[0])][@intCast(curr[1])] == 'O') {
                curr += move;
            }
            var temp = curr;
            while (!std.meta.eql(temp, new_pos)) {
                warehouse[@intCast(temp[0])][@intCast(temp[1])] = 'O';
                temp -= move;
            }
        }

        // Move the '@' character
        warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.';
        warehouse[x][y] = '@';
    }

    return new_pos;
}

fn getDirection(move: u8) Vec2 {
    return switch (move) {
        '^' => Vec2{ -1, 0 },
        '>' => Vec2{ 0, 1 },
        'v' => Vec2{ 1, 0 },
        '<' => Vec2{ 0, -1 },
        else => unreachable,
    };
}

fn willCauseCollision(warehouse: [][]u8, pos: Vec2, move: Vec2) bool {
    var curr = pos;
    while (true) {
        curr += move;
        const x: usize = @intCast(curr[0]);
        const y: usize = @intCast(curr[1]);
        if (warehouse[x][y] == '.') {
            return false;
        } else if (warehouse[x][y] == '#') {
            return true;
        }
    }
    return false;
}
