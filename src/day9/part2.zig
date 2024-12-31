const std = @import("std");
const Context = @import("part1.zig").Context;
const Disk = @import("disk.zig").Disk;

pub fn part2(ctx: *Context) ![]const u8 {
    var disk = try ctx.disk.clone();
    defer disk.deinit();

    try disk.defrag();

    var sum: u64 = 0;
    for (0..disk.blocks.len) |i| {
        const block = disk.blocks[i];
        switch (block) {
            .file => |file| sum += i * file,
            .free => {},
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
