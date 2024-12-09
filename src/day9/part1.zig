const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    const disk = try parseDisk(allocator, std.mem.trimRight(u8, file_contents, "\n"));
    defer allocator.free(disk);

    var start = disk.len - 1;
    while (start >= 0) {
        const block = disk[start];
        switch (block) {
            .file => |file| {
                // find index of first free block
                var free_idx: usize = undefined;
                for (0..disk.len) |i| {
                    if (disk[i] == .free) {
                        free_idx = i;
                        // break;
                    }
                }
                disk[free_idx] = DiskBlock{ .file = file };
                disk[start] = DiskBlock{ .free = {} };
            },
            .free => {},
        }

        // check if compacted
        if (isCompacted(disk)) break;

        if (start == 0) break;
        start -= 1;
    }

    var sum: u64 = 0;
    for (0..disk.len) |i| {
        const block = disk[i];
        switch (block) {
            .file => |file| sum += i * file,
            .free => {},
        }
    }
    std.debug.print("{d}\n", .{sum});
}

fn printDisk(disk: []DiskBlock) void {
    for (0..disk.len) |i| {
        const block = disk[i];
        switch (block) {
            .file => |file| std.debug.print("{d}", .{file}),
            .free => std.debug.print(".", .{}),
        }
    }
    std.debug.print("\n", .{});
}

const DiskBlock = union(enum) {
    file: u64,
    free,
};

fn isCompacted(disk: []DiskBlock) bool {
    var free_block_found = false;
    for (0..disk.len) |i| {
        const block = disk[i];
        switch (block) {
            .file => {
                if (free_block_found) return false;
            },
            .free => free_block_found = true,
        }
    }

    return true;
}

fn parseDisk(allocator: std.mem.Allocator, disk_map: []const u8) ![]DiskBlock {
    var disk = std.ArrayList(DiskBlock).init(allocator);
    var is_file = true;
    var file_id: u64 = 0;
    for (disk_map) |char| {
        const size = try std.fmt.parseInt(u64, &[_]u8{char}, 10);
        for (0..size) |j| {
            _ = j;
            try disk.append(if (is_file) DiskBlock{ .file = file_id } else DiskBlock{ .free = {} });
        }
        if (is_file) file_id += 1;
        is_file = !is_file;
    }

    return disk.toOwnedSlice();
}

const Disk = struct {
    blocks: []DiskBlock,
    file_map: std.AutoArrayHashMap(u64, struct { idx: usize, size: u64 }),
};

fn parseDisk2(allocator: std.mem.Allocator, disk_map: []const u8) !Disk {
    var blocks = std.ArrayList(DiskBlock).init(allocator);
    var file_map = std.AutoArrayHashMap(u64, usize).init(allocator);
    var is_file = true;
    var file_id: u64 = 0;
    for (disk_map) |char| {
        const size = try std.fmt.parseInt(u64, &[_]u8{char}, 10);
        for (0..size) |i| {
            var block: DiskBlock = undefined;
            if (is_file) {
                block = DiskBlock{ .file = file_id };
            } else {
                block = DiskBlock{ .free = {} };
            }
            try blocks.append(block);
            if (is_file and i == 0) {
                try file_map.put(file_id, .{ .idx = blocks.len - 1, .size = size });
            }
        }
        if (is_file) file_id += 1;
        is_file = !is_file;
    }

    return Disk{ .blocks = blocks.toOwnedSlice(), .file_map = file_map };
}
