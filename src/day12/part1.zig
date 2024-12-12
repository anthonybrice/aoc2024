const std = @import("std");
const util = @import("../main.zig");
const M = std.math.big.int.Managed;

const Region = struct {
    area: i64,
    perimeter: i64,
};

// const Position = struct {
//     row: i64,
//     col: i64,
// };

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeAny(u8, file_contents, "\n");
    var garden = std.AutoArrayHashMap([2]i64, u8).init(allocator);
    defer garden.deinit();
    var row: i64 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |c, col| {
            try garden.put(.{ row, @intCast(col) }, c);
        }
        row += 1;
    }

    var visited = std.AutoArrayHashMap([2]i64, void).init(allocator);
    defer visited.deinit();

    var areas = std.AutoArrayHashMap(u8, std.ArrayList(Region)).init(allocator);
    defer {
        for (areas.values()) |regions| regions.deinit();
        areas.deinit();
    }

    for (garden.keys()) |key| {
        const pos = key;
        const letter = garden.get(pos).?;
        if (!visited.contains(pos)) {
            const result = try floodFill(allocator, garden, &visited, pos, letter);
            if (!areas.contains(letter)) {
                var l = std.ArrayList(Region).init(allocator);
                try l.append(result);
                try areas.put(letter, l);
            } else {
                var l = areas.get(letter).?;
                try l.append(result);
                try areas.put(letter, l);
            }
        }
    }

    var sum: i64 = 0;
    for (areas.keys()) |key| {
        // const letter = key;
        const regions = areas.get(key).?;
        for (regions.items) |region| {
            // std.debug.print("Letter: {c}, Area: {d}, Perimeter: {d}\n", .{ letter, region.area, region.perimeter });
            sum += region.area * region.perimeter;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

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
