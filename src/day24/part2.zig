const std = @import("std");
const util = @import("../main.zig");
const p1 = @import("part1.zig");

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var device = try p1.Device.init(allocator, file_contents);
    defer device.deinit();

    const switched_outputs = try device.findSwitchedOutputs();
    defer allocator.free(switched_outputs);

    var l = std.ArrayList([]const u8).init(allocator);
    defer l.deinit();
    for (switched_outputs) |output| {
        try l.append(output[0]);
        try l.append(output[1]);
    }
    const acc = try l.toOwnedSlice();
    defer allocator.free(acc);
    std.mem.sort([]const u8, acc, {}, compareStrings);
    for (acc) |output| {
        std.debug.print("{s},", .{output});
    }
    std.debug.print("\n", .{});
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

const RcaResult = struct {
    result: u64,
    carry: u64,
};

fn rca(a: u64, b: u64, n: u64) RcaResult {
    var result: u64 = 0;
    var carry: u64 = 0;

    for (0..n) |i| {
        const bit_a = (a >> @intCast(i)) & 1;
        const bit_b = (b >> @intCast(i)) & 1;

        const sum_bit = bit_a ^ bit_b ^ carry;

        carry = (bit_a & bit_b) | (carry & (bit_a ^ bit_b));

        result |= sum_bit << @intCast(i);
    }

    return .{ .result = result, .carry = carry };
}

test "rca" {
    const a: u64 = 255;
    const b: u64 = 1;

    const result = rca(a, b, 8);
    try std.testing.expectEqual(RcaResult{ .result = 0, .carry = 1 }, result);
}
