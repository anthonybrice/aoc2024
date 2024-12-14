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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.debug.print("Memory leak detected\n", .{});
    }
    // const allocator = std.heap.c_allocator;
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // Skip the program name.
    const part = args.next().?;
    const input_file = args.next().?;

    const case = std.meta.stringToEnum(Case, part);
    if (case == null) {
        return std.debug.print("Invalid part: {s}\n", .{part});
    }

    switch (case.?) {
        .d1p1 => try d1p1.main(allocator, input_file),
        .d1p2 => try d1p2.main(allocator, input_file),
        .d2p1 => try d2p1.main(allocator, input_file),
        .d2p2 => try d2p2.main(allocator, input_file),
        .d3p1 => try d3p1.main(allocator, input_file),
        .d3p2 => try d3p2.main(allocator, input_file),
        .d4p1 => try d4p1.main(allocator, input_file),
        .d4p2 => try d4p2.main(allocator, input_file),
        .d5p1 => try d5p1.main(allocator, input_file),
        .d5p2 => try d5p2.main(allocator, input_file),
        .d6p1 => try d6p1.main(allocator, input_file),
        .d6p2 => try d6p2.main(allocator, input_file),
        .d7p1 => try d7p1.main(allocator, input_file),
        .d7p2 => try d7p2.main(allocator, input_file),
        .d8p1 => try d8p1.main(allocator, input_file),
        .d8p2 => try d8p2.main(allocator, input_file),
        .d9p1 => try d9p1.main(allocator, input_file),
        .d9p2 => try d9p2.main(allocator, input_file),
        .d10p1 => try d10p1.main(allocator, input_file),
        .d10p2 => try d10p2.main(allocator, input_file),
        .d11p1 => try d11p1.main(allocator, input_file),
        .d11p2 => try d11p2.main(allocator, input_file),
        .d12p1 => try d12p1.main(allocator, input_file),
        .d12p2 => try d12p2.main(allocator, input_file),
        .d13p1 => try d13p1.main(allocator, input_file),
        .d13p2 => try d13p2.main(allocator, input_file),
        .d14p1 => try d14p1.main(allocator, input_file),
        .d14p2 => try d14p2.main(allocator, input_file),
    }
}

const Case = enum {
    d1p1,
    d1p2,
    d2p1,
    d2p2,
    d3p1,
    d3p2,
    d4p1,
    d4p2,
    d5p1,
    d5p2,
    d6p1,
    d6p2,
    d7p1,
    d7p2,
    d8p1,
    d8p2,
    d9p1,
    d9p2,
    d10p1,
    d10p2,
    d11p1,
    d11p2,
    d12p1,
    d12p2,
    d13p1,
    d13p2,
    d14p1,
    d14p2,
};

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    var in = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer in.close();

    return try in.readToEndAlloc(allocator, std.math.maxInt(usize));
}
