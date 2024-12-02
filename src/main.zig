const std = @import("std");
const d1p1 = @import("day1/part1.zig");
const d1p2 = @import("day1/part2.zig");
const d2p1 = @import("day2/part1.zig");
const d2p2 = @import("day2/part2.zig");
const d3p1 = @import("day3/part1.zig");
const d3p2 = @import("day3/part2.zig");

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
    }
}

const Case = enum {
    d1p1,
    d1p2,
    d2p1,
    d2p2,
    d3p1,
    d3p2,
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
