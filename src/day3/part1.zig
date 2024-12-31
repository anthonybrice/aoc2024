const std = @import("std");
const Allocator = std.mem.Allocator;
const mvzr = @import("mvzr");

pub const Context = struct {
    allocator: Allocator,
    input: []const u8,
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.input = in;
    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    const mul_regex = mvzr.compile("mul\\((\\d+),(\\d+)\\)").?;
    var mul_iter = mul_regex.iterator(ctx.input);

    var sum: u64 = 0;
    while (mul_iter.next()) |match| {
        const instruction = match.slice;

        const int_regex = mvzr.compile("\\d+").?;
        var int_iter = int_regex.iterator(instruction);
        const int1 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);
        const int2 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);

        sum += int1 * int2;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
