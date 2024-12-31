const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;

pub fn part2(ctx: Context) ![]const u8 {
    const allocator = ctx.allocator;
    var stone_to_count_map = std.AutoArrayHashMap(u64, u64).init(allocator);
    defer stone_to_count_map.deinit();

    for (ctx.init_stones_.items) |num| {
        const count = stone_to_count_map.get(num) orelse 0;
        try stone_to_count_map.put(num, count + 1);
    }

    var stone_to_stones_map = std.AutoArrayHashMap(u64, []u64).init(allocator);
    defer {
        for (stone_to_stones_map.values()) |stones| allocator.free(stones);
        stone_to_stones_map.deinit();
    }

    var current_map = stone_to_count_map;
    for (0..75) |_| {
        var new_map = std.AutoArrayHashMap(u64, u64).init(allocator);
        for (current_map.keys()) |stone| {
            const new_nums = try doBlink(
                allocator,
                stone,
                &stone_to_stones_map,
            );
            for (new_nums) |new_num| {
                const old_count = current_map.get(stone) orelse 0;
                if (new_map.get(new_num)) |new_count| {
                    try new_map.put(new_num, new_count + old_count);
                } else {
                    try new_map.put(new_num, old_count);
                }
            }
        }
        current_map.deinit();
        current_map = new_map;
    }

    var count: u64 = 0;
    for (current_map.values()) |v| {
        count += v;
    }
    current_map.deinit();

    return try std.fmt.allocPrint(allocator, "{d}", .{count});
}

fn doBlink(
    allocator: std.mem.Allocator,
    stone: u64,
    stone_to_stones_map: *std.AutoArrayHashMap(u64, []u64),
) ![]u64 {
    if (stone_to_stones_map.contains(stone)) {
        return stone_to_stones_map.get(stone).?;
    }

    var next_stones = std.ArrayList(u64).init(allocator);

    if (stone == 0) {
        try next_stones.append(1);
    } else {
        const digits = countDigits(stone);
        if (digits % 2 == 0) {
            const halves = try splitEvenDigits(allocator, stone);
            try next_stones.append(halves[0]);
            try next_stones.append(halves[1]);
        } else {
            try next_stones.append(stone * 2024);
        }
    }

    const slice = try next_stones.toOwnedSlice();
    try stone_to_stones_map.put(stone, slice);

    return slice;
}

fn splitEvenDigits(allocator: std.mem.Allocator, num: u64) ![2]u64 {
    const num_digits = countDigits(num);
    const buf = try allocator.alloc(u8, num_digits);
    defer allocator.free(buf);
    const num_string = try std.fmt.bufPrint(buf, "{d}", .{num});
    const half = num_digits / 2;

    const left = try std.fmt.parseInt(u64, num_string[0..half], 10);
    const right = try std.fmt.parseInt(u64, num_string[half..num_digits], 10);

    return [_]u64{ left, right };
}

fn countDigits(num: u64) u64 {
    var count: u64 = 0;
    var currentNum = num;

    while (currentNum > 0) {
        currentNum /= 10;
        count += 1;
    }

    return count;
}
