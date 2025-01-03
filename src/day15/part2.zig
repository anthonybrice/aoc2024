const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    const warehouse: [][]u8 = try parseWarehouse(allocator, ctx.raw_warehouse);
    defer {
        for (warehouse) |line| {
            allocator.free(line);
        }
        allocator.free(warehouse);
    }

    var pos: Vec2 = try getRobot(warehouse);

    for (ctx.moves) |move| {
        pos = doMove(warehouse, pos, getDirection(move));
    }

    var sum: usize = 0;
    for (warehouse, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == '[') {
                sum += 100 * row + col;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn getRobot(warehouse: [][]u8) !Vec2 {
    for (warehouse, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == '@') {
                return Vec2{ @intCast(row), @intCast(col) };
            }
        }
    }
    return error.NotFound;
}

fn parseWarehouse(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var warehouse = std.ArrayList([]u8).init(allocator);

    while (lines.next()) |line| {
        var new_line = std.ArrayList(u8).init(allocator);
        for (line) |char| {
            switch (char) {
                '#', '.' => try new_line.appendSlice(&.{ char, char }),
                'O' => try new_line.appendSlice("[]"),
                '@' => try new_line.appendSlice("@."),
                else => unreachable,
            }
        }
        try warehouse.append(try new_line.toOwnedSlice());
    }

    return warehouse.toOwnedSlice();
}

fn doMove(warehouse: [][]u8, pos: Vec2, dir: Vec2) Vec2 {
    var new_pos = pos;

    if (!isCollision(warehouse, pos, dir)) {
        new_pos = pos + dir;
        const x: usize = @intCast(new_pos[0]);
        const y: usize = @intCast(new_pos[1]);
        if (std.meta.eql(dir, Vec2{ -1, 0 }) or std.meta.eql(dir, Vec2{ 1, 0 })) {
            switch (warehouse[x][y]) {
                '.' => warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.',
                '[' => {
                    _ = moveBoxUpOrDown(warehouse, .{ new_pos, new_pos + Vec2{ 0, 1 } }, dir);
                    warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.';
                },
                ']' => {
                    _ = moveBoxUpOrDown(warehouse, .{ new_pos + Vec2{ 0, -1 }, new_pos }, dir);
                    warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.';
                },
                else => unreachable,
            }
        } else {
            switch (warehouse[x][y]) {
                '.' => warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.',
                '[', ']' => {
                    if (std.meta.eql(dir, Vec2{ 0, 1 })) {
                        _ = moveBoxRight(warehouse, .{ new_pos, new_pos + dir });
                    } else {
                        _ = moveBoxLeft(warehouse, .{ new_pos + dir, new_pos });
                    }
                    warehouse[@intCast(pos[0])][@intCast(pos[1])] = '.';
                },
                else => unreachable,
            }
        }

        warehouse[x][y] = '@';
    }

    return new_pos;
}

fn moveBoxUpOrDown(warehouse: [][]u8, pos: [2]Vec2, dir: Vec2) [2]Vec2 {
    const next: [2]Vec2 = .{ pos[0] + dir, pos[1] + dir };

    const x1: usize = @intCast(next[0][0]);
    const y1: usize = @intCast(next[0][1]);
    const x2: usize = @intCast(next[1][0]);
    const y2: usize = @intCast(next[1][1]);

    const char1 = warehouse[x1][y1];
    const char2 = warehouse[x2][y2];

    if (char1 == '.' and char2 == '.') {
        warehouse[@intCast(pos[0][0])][@intCast(pos[0][1])] = '.';
        warehouse[@intCast(pos[1][0])][@intCast(pos[1][1])] = '.';
        warehouse[x1][y1] = '[';
        warehouse[x2][y2] = ']';

        return next;
    } else if (char1 == '[' and char2 == ']') {
        _ = moveBoxUpOrDown(warehouse, next, dir);

        return moveBoxUpOrDown(warehouse, pos, dir);
    } else if (char1 == ']' and char2 == '[') {
        _ = moveBoxUpOrDown(warehouse, .{ next[0] + Vec2{ 0, -1 }, next[0] }, dir);
        _ = moveBoxUpOrDown(warehouse, .{ next[1], next[1] + Vec2{ 0, 1 } }, dir);

        return moveBoxUpOrDown(warehouse, pos, dir);
    } else if (char1 == ']' and char2 == '.') {
        _ = moveBoxUpOrDown(warehouse, .{ next[0] + Vec2{ 0, -1 }, next[0] }, dir);
        return moveBoxUpOrDown(warehouse, pos, dir);
    } else if (char1 == '.' and char2 == '[') {
        _ = moveBoxUpOrDown(warehouse, .{ next[1], next[1] + Vec2{ 0, 1 } }, dir);
        return moveBoxUpOrDown(warehouse, pos, dir);
    }

    std.debug.print("Error: Invalid box move\n", .{});
    std.debug.print("pos: {any}, dir: {any} \n", .{ pos, dir });
    for (warehouse) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
    unreachable;
}

fn moveBoxRight(warehouse: [][]u8, pos: [2]Vec2) [2]Vec2 {
    const dir = Vec2{ 0, 1 };
    const next: [2]Vec2 = .{ pos[0] + dir, pos[1] + dir };

    const x1: usize = @intCast(next[0][0]);
    const y1: usize = @intCast(next[0][1]);
    const x2: usize = @intCast(next[1][0]);
    const y2: usize = @intCast(next[1][1]);

    // const char1 = warehouse[x1][y1];
    const char2 = warehouse[x2][y2];

    if (char2 == '.') {
        warehouse[@intCast(pos[0][0])][@intCast(pos[0][1])] = '.';
        warehouse[x1][y1] = '[';
        warehouse[x2][y2] = ']';

        return next;
    } else if (char2 == '[') {
        _ = moveBoxRight(warehouse, .{ next[1], next[1] + dir });

        return moveBoxRight(warehouse, pos);
    }

    std.debug.print("Error: Invalid box move\n", .{});
    std.debug.print("pos: {any}, dir: {any} \n", .{ pos, dir });
    for (warehouse) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
    unreachable;
}

fn moveBoxLeft(warehouse: [][]u8, pos: [2]Vec2) [2]Vec2 {
    const dir = Vec2{ 0, -1 };
    const next: [2]Vec2 = .{ pos[0] + dir, pos[1] + dir };

    const x1: usize = @intCast(next[0][0]);
    const y1: usize = @intCast(next[0][1]);
    const x2: usize = @intCast(next[1][0]);
    const y2: usize = @intCast(next[1][1]);

    const char1 = warehouse[x1][y1];
    // const char2 = warehouse[x2][y2];

    if (char1 == '.') {
        warehouse[@intCast(pos[1][0])][@intCast(pos[1][1])] = '.';
        warehouse[x1][y1] = '[';
        warehouse[x2][y2] = ']';

        return next;
    } else if (char1 == ']') {
        _ = moveBoxLeft(warehouse, .{ next[0] + dir, next[0] });

        return moveBoxLeft(warehouse, pos);
    }

    std.debug.print("Error: Invalid box move\n", .{});
    std.debug.print("pos: {any}, dir: {any} \n", .{ pos, dir });
    for (warehouse) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
    unreachable;
}

fn getDirection(dir: u8) Vec2 {
    return switch (dir) {
        '^' => Vec2{ -1, 0 },
        '>' => Vec2{ 0, 1 },
        'v' => Vec2{ 1, 0 },
        '<' => Vec2{ 0, -1 },
        else => unreachable,
    };
}

fn isCollision(warehouse: [][]u8, pos: Vec2, dir: Vec2) bool {
    const next = pos + dir;
    // if (next[0] < 0 or next[1] < 0) return true;
    const x: usize = @intCast(next[0]);
    const y: usize = @intCast(next[1]);
    if (std.meta.eql(dir, Vec2{ -1, 0 }) or std.meta.eql(dir, Vec2{ 1, 0 })) {
        switch (warehouse[x][y]) {
            '#' => return true,
            '.' => return false,
            '[' => return isCollision(warehouse, next, dir) or
                isCollision(warehouse, next + Vec2{ 0, 1 }, dir),
            ']' => return isCollision(warehouse, next, dir) or
                isCollision(warehouse, next + Vec2{ 0, -1 }, dir),
            else => unreachable,
        }
    } else {
        switch (warehouse[x][y]) {
            '#' => return true,
            '.' => return false,
            '[', ']' => return isCollision(warehouse, next + dir, dir),
            else => unreachable,
        }
    }
}
