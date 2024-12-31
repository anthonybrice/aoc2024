const std = @import("std");
const Context = @import("part1.zig").Context;
const mvzr = @import("mvzr");

pub fn part2(ctx: Context) ![]const u8 {
    const mul_regex = mvzr.compile("mul\\((\\d+),(\\d+)\\)|do\\(\\)|don't\\(\\)").?;
    var mul_iter = mul_regex.iterator(ctx.input);

    var do = true;
    var sum: u64 = 0;
    while (mul_iter.next()) |match| {
        const instruction = match.slice;

        if (std.mem.eql(u8, instruction, "do()")) {
            do = true;
        } else if (std.mem.eql(u8, instruction, "don't()")) {
            do = false;
        } else if (do) {
            const int_regex = mvzr.compile("\\d+").?;
            var int_iter = int_regex.iterator(instruction);
            const int1 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);
            const int2 = try std.fmt.parseInt(u64, int_iter.next().?.slice, 10);

            sum += int1 * int2;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
