const std = @import("std");
const Disk = @import("disk.zig").Disk;

pub const Context = struct {
    allocator: std.mem.Allocator,
    disk: Disk,

    pub fn deinit(self: *Context) void {
        self.disk.deinit();
    }
};

pub fn parse(allocator: std.mem.Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.disk = try Disk.initFromDenseMap(
        allocator,
        std.mem.trimRight(u8, input, "\n"),
    );

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var disk = try ctx.disk.clone();
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

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
