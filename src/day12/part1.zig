const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    garden: std.AutoArrayHashMap([2]i64, u8),

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.garden);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.garden = std.AutoArrayHashMap([2]i64, u8).init(allocator);

    var lines = std.mem.tokenizeAny(u8, in, "\n");
    var row: i64 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |c, col| {
            try ctx.garden.put(.{ row, @intCast(col) }, c);
        }
        row += 1;
    }

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var visited = std.AutoArrayHashMap([2]i64, void).init(ctx.allocator);
    defer visited.deinit();

    var areas = std.AutoArrayHashMap(u8, std.ArrayList(Region)).init(ctx.allocator);
    defer {
        for (areas.values()) |regions| regions.deinit();
        areas.deinit();
    }

    for (ctx.garden.keys()) |key| {
        const pos = key;
        const letter = ctx.garden.get(pos).?;
        if (!visited.contains(pos)) {
            const result = try floodFill(ctx.allocator, ctx.garden, &visited, pos, letter);
            if (!areas.contains(letter)) {
                try areas.put(letter, std.ArrayList(Region).init(ctx.allocator));
            }
            var r = areas.get(letter).?;
            try r.append(result);
            try areas.put(letter, r);
        }
    }

    var sum: i64 = 0;
    for (areas.keys()) |key| {
        const regions = areas.get(key).?;
        for (regions.items) |region| {
            sum += region.area * region.perimeter;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

const Region = struct {
    area: i64,
    perimeter: i64,
};

fn floodFill(
    allocator: std.mem.Allocator,
    garden: std.AutoArrayHashMap([2]i64, u8),
    visited: *std.AutoArrayHashMap([2]i64, void),
    start: [2]i64,
    letter: u8,
) !Region {
    const directions = [_][2]i64{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } };
    var stack = std.ArrayList([2]i64).init(allocator);
    defer stack.deinit();
    try stack.append(.{ start[0], start[1] });

    var area: i64 = 0;
    var perimeter: i64 = 0;

    while (stack.items.len > 0) {
        const pos = stack.pop();
        if (visited.contains(.{ pos[0], pos[1] })) continue;
        try visited.put(.{ pos[0], pos[1] }, {});

        area += 1;
        // var is_perimeter = false;

        for (directions) |dir| {
            const new_row = pos[0] + dir[0];
            const new_col = pos[1] + dir[1];
            const new_pos = [2]i64{ new_row, new_col };

            if (!garden.contains(new_pos) or garden.get(new_pos) != letter) {
                perimeter += 1;
            } else if (!visited.contains(new_pos)) {
                try stack.append(.{ new_row, new_col });
            }
        }
    }

    return Region{ .area = area, .perimeter = perimeter };
}
