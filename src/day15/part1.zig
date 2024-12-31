const std = @import("std");
const util = @import("../main.zig");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    raw_warehouse: []const u8,
    moves: []const u8,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.raw_warehouse);
        self.allocator.free(self.moves);
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;

    var sections = std.mem.tokenizeSequence(u8, input, "\n\n");

    const raw_warehouse_ = sections.next().?;
    const raw_warehouse = try allocator.alloc(u8, raw_warehouse_.len);
    @memcpy(raw_warehouse, raw_warehouse_);
    ctx.raw_warehouse = raw_warehouse;

    ctx.moves = try parseMoves(allocator, sections.next().?);

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    const warehouse: [][]u8 = try parseWarehouse(allocator, ctx.raw_warehouse);
    defer {
        for (warehouse) |line| {
            allocator.free(line);
        }
        allocator.free(warehouse);
    }

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

    for (ctx.moves) |move| {
        pos = doMove(warehouse, pos, getDirection(move));
    }

    var sum: usize = 0;
    for (warehouse, 0..) |line, row| {
        for (line, 0..) |char, col| {
            if (char == 'O') {
                sum += 100 * row + col;
            }
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
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
