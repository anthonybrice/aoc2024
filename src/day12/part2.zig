const std = @import("std");
const util = @import("../main.zig");
const M = std.math.big.int.Managed;

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeAny(u8, file_contents, "\n");
    var garden = std.AutoArrayHashMap([2]i64, u8).init(allocator);
    defer garden.deinit();
    var row: i64 = 0;
    var line_len: usize = 0;
    while (lines.next()) |line| {
        line_len = @intCast(line.len);
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
                try areas.put(letter, std.ArrayList(Region).init(allocator));
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
            sum += region.corners * region.area;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

const Region = struct {
    area: i64,
    corners: i64,
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

    var corners: i64 = 0;
    while (stack.items.len > 0) {
        const pos = stack.pop();
        if (visited.contains(.{ pos[0], pos[1] })) continue;
        try visited.put(.{ pos[0], pos[1] }, {});

        area += 1;
        corners += countCorners(garden, pos);

        for (directions) |dir| {
            const new_row = pos[0] + dir[0];
            const new_col = pos[1] + dir[1];
            const new_pos = [2]i64{ new_row, new_col };

            if (garden.contains(new_pos) and garden.get(new_pos) == letter and !visited.contains(new_pos)) {
                try stack.append(new_pos);
            }
        }
    }

    return Region{ .area = area, .corners = corners };
}

fn countCorners(garden: std.AutoArrayHashMap([2]i64, u8), pos: [2]i64) i64 {
    const dir = [_][2]i64{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
    const d1s = [_][2]i64{ dir[0], dir[0], dir[2], dir[2] };
    const d2s = [_][2]i64{ dir[1], dir[3], dir[1], dir[3] };

    var corners: i64 = 0;
    for (0..d1s.len) |i| {
        const d1 = d1s[i];
        const d2 = d2s[i];
        const d3 = .{ d1[0] + d2[0], d1[1] + d2[1] };

        const c1 = garden.get(.{ pos[0] + d1[0], pos[1] + d1[1] }) orelse ' ';
        const c2 = garden.get(.{ pos[0] + d2[0], pos[1] + d2[1] }) orelse ' ';
        const c3 = garden.get(.{ pos[0] + d3[0], pos[1] + d3[1] }) orelse ' ';

        const l = garden.get(pos).?;
        if ((l != c1 and l != c2) or (l == c1 and l == c2 and l != c3)) {
            corners += 1;
        }
    }

    return corners;
}
