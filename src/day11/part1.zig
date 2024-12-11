const std = @import("std");
const util = @import("../main.zig");
const M = std.math.big.int.Managed;

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var init_string = std.mem.tokenizeAny(u8, file_contents, " \n");
    var init_stones = std.ArrayList(M).init(allocator);

    while (init_string.next()) |v| {
        const num = try std.fmt.parseInt(u64, v, 10);
        try init_stones.append(try M.initSet(allocator, num));
    }

    var zero = try M.init(allocator);
    defer zero.deinit();
    var current = init_stones;
    for (0..25) |i| {
        std.debug.print("starting loop: {d}\n", .{i});
        var next_stones = std.ArrayList(M).init(allocator);

        for (current.items) |num| {
            if (M.eql(num, zero)) {
                try next_stones.append(try M.initSet(allocator, 1));
            } else if (try countDigits(allocator, num) % 2 == 0) {
                const halves = try splitEvenDigits(allocator, num);
                try next_stones.append(halves[0]);
                try next_stones.append(halves[1]);
            } else {
                var m = try M.initSet(allocator, 2024);
                defer m.deinit();
                var new = try M.init(allocator);
                try M.mul(&new, &num, &m);
                try next_stones.append(new);
            }
        }

        if (i != 24) {
            for (current.items) |*item| item.deinit();
            current.deinit();
        }

        current = next_stones;
    }

    std.debug.print("{d}\n", .{current.items.len});
    for (current.items) |*item| item.deinit();
    current.deinit();
}

fn splitEvenDigits(allocator: std.mem.Allocator, num: M) ![2]M {
    // const digit_count = countDigits(allocator, num);

    var num_string = try num.toString(allocator, 10, std.fmt.Case.lower);
    const digit_count = num_string.len;
    defer allocator.free(num_string);
    const half = digit_count / 2;
    const first_half = num_string[0..half];
    const second_half = num_string[half..digit_count];

    var i = try M.init(allocator);
    try i.setString(10, first_half);
    var j = try M.init(allocator);
    try j.setString(10, second_half);

    return [_]M{ i, j };
}

fn countDigits(allocator: std.mem.Allocator, num: M) !u64 {
    const num_string = try num.toString(allocator, 10, std.fmt.Case.lower);
    defer allocator.free(num_string);
    return num_string.len;
}
