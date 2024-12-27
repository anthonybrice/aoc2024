const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    var init_ns = std.ArrayList(i64).init(allocator);
    defer init_ns.deinit();
    while (lines.next()) |line| {
        const n = try std.fmt.parseInt(i64, line, 10);
        try init_ns.append(n);
    }

    var prices = std.ArrayList([]i64).init(allocator);
    defer {
        for (prices.items) |l| {
            allocator.free(l);
        }
        prices.deinit();
    }
    for (init_ns.items) |n| {
        var curr = n;
        var l = std.ArrayList(i64).init(allocator);
        defer l.deinit();
        try l.append(@mod(curr, 10));
        for (0..2000) |_| {
            curr = nextSecretNumber(curr);
            try l.append(@mod(curr, 10));
        }
        try prices.append(try l.toOwnedSlice());
    }

    const max = maxBananas(prices.items);
    std.debug.print("{d}\n", .{max});
}

fn nextSecretNumber(n: i64) i64 {
    const n1 = n * 64;
    const n2 = n1 ^ n;
    const n3 = @mod(n2, 16777216);
    const n4 = @divTrunc(n3, 32);
    const n5 = n4 ^ n3;
    const n6 = @mod(n5, 16777216);
    const n7 = n6 * 2048;
    const n8 = n7 ^ n6;
    const n9 = @mod(n8, 16777216);

    return n9;
}

fn getPriceFromSeq(ns: []i64, seq: [4]i64) ?i64 {
    for (ns[4..], 4..) |n, i| {
        const c1 = ns[i - 3] - ns[i - 4];
        const c2 = ns[i - 2] - ns[i - 3];
        const c3 = ns[i - 1] - ns[i - 2];
        const c4 = n - ns[i - 1];

        if (c1 == seq[0] and c2 == seq[1] and c3 == seq[2] and c4 == seq[3]) {
            return n;
        }
    }

    return null;
}

fn maxBananas(prices: [][]i64) i64 {
    var curr_max: i64 = 0;

    var c1: i64 = -9;
    while (c1 <= 9) {
        var c2: i64 = -9;
        while (c2 <= 9) {
            var c3: i64 = -9;
            while (c3 <= 9) {
                var c4: i64 = -9;
                while (c4 <= 9) {
                    var curr: i64 = 0;
                    for (prices) |l| {
                        curr += getPriceFromSeq(l, .{ c1, c2, c3, c4 }) orelse continue;
                        if (curr > curr_max) {
                            curr_max = curr;
                        }
                    }
                    c4 += 1;
                }
                c3 += 1;
            }
            c2 += 1;
        }
        c1 += 1;
    }

    return curr_max;
}
