const std = @import("std");
const clap = @import("clap");
const d1p1 = @import("day1/part1.zig");
const d1p2 = @import("day1/part2.zig");
const d2p1 = @import("day2/part1.zig");
const d2p2 = @import("day2/part2.zig");
const d3p1 = @import("day3/part1.zig");
const d3p2 = @import("day3/part2.zig");
const d4p1 = @import("day4/part1.zig");
const d4p2 = @import("day4/part2.zig");
const d5p1 = @import("day5/part1.zig");
const d5p2 = @import("day5/part2.zig");
const d6p1 = @import("day6/part1.zig");
const d6p2 = @import("day6/part2.zig");
const d7p1 = @import("day7/part1.zig");
const d7p2 = @import("day7/part2.zig");
const d8p1 = @import("day8/part1.zig");
const d8p2 = @import("day8/part2.zig");
const d9p1 = @import("day9/part1.zig");
const d9p2 = @import("day9/part2.zig");
const d10p1 = @import("day10/part1.zig");
const d10p2 = @import("day10/part2.zig");
const d11p1 = @import("day11/part1.zig");
const d11p2 = @import("day11/part2.zig");
const d12p1 = @import("day12/part1.zig");
const d12p2 = @import("day12/part2.zig");
const d13p1 = @import("day13/part1.zig");
const d13p2 = @import("day13/part2.zig");
const d14p1 = @import("day14/part1.zig");
const d14p2 = @import("day14/part2.zig");
const d15p1 = @import("day15/part1.zig");
const d15p2 = @import("day15/part2.zig");
const d16p1 = @import("day16/part1.zig");
const d16p2 = @import("day16/part2.zig");
const d17p1 = @import("day17/part1.zig");
const d17p2 = @import("day17/part2.zig");
const d18p1 = @import("day18/part1.zig");
const d18p2 = @import("day18/part2.zig");
const d19p1 = @import("day19/part1.zig");
const d19p2 = @import("day19/part2.zig");
const d20p1 = @import("day20/part1.zig");
const d20p2 = @import("day20/part2.zig");
const d21p1 = @import("day21/part1.zig");
const d21p2 = @import("day21/part2.zig");
const d22p1 = @import("day22/part1.zig");
const d22p2 = @import("day22/part2.zig");
const d23p1 = @import("day23/part1.zig");
const d23p2 = @import("day23/part2.zig");
const d24p1 = @import("day24/part1.zig");
const d24p2 = @import("day24/part2.zig");
const d25p1 = @import("day25/part1.zig");

const day = @import("day24/day.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const path = "in/day24.txt";

    // try d17p2.main(allocator, path);

    var in = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer in.close();

    const file_contents = try in.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    const ctx = try day.parse(allocator, file_contents);
    defer {
        ctx.deinit();
        allocator.destroy(ctx);
    }
    const foo = try day.part1(ctx);
    defer allocator.free(foo);
    std.debug.print("{s}\n", .{foo});
    const r = try day.part2(ctx);
    defer allocator.free(r);
    std.debug.print("{s}\n", .{r});
}
