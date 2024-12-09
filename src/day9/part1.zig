const std = @import("std");
const util = @import("../main.zig");
const d9p2 = @import("./part2.zig");

const Disk = d9p2.Disk;

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    // const disk = try parseDisk(allocator, std.mem.trimRight(u8, file_contents, "\n"));
    var disk = try Disk.initFromDenseMap(
        allocator,
        std.mem.trimRight(u8, file_contents, "\n"),
    );
    defer disk.deinit();

    try disk.compact();

    var sum: u64 = 0;
    for (0..disk.blocks.len) |i| {
        const block = disk.blocks[i];
        switch (block) {
            .file => |file| sum += i * file,
            .free => {},
        }
    }
    std.debug.print("{d}\n", .{sum});
}
