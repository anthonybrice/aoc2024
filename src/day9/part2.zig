const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var disk = try parseDisk(allocator, std.mem.trimRight(u8, file_contents, "\n"));
    defer {
        allocator.free(disk.blocks);
        disk.file_map.deinit();
    }

    var max_file_id: u64 = 0;
    for (disk.file_map.keys()) |file_id| {
        if (file_id > max_file_id) max_file_id = file_id;
    }

    var file_id = max_file_id;
    while (file_id >= 0) {
        const file = disk.file_map.get(file_id).?;

        // find first free segment in which file will fit
        for (0..file.idx) |i| {
            if (disk.blocks[i] == .free) {
                var size: u64 = 0;
                for (i..disk.blocks.len) |j| {
                    if (disk.blocks[j] == .free) {
                        size += 1;
                    } else {
                        break;
                    }
                }
                if (size >= file.size) {
                    for (i..i + file.size) |j| {
                        disk.blocks[j] = DiskBlock{ .file = file_id };
                    }
                    for (file.idx..file.idx + file.size) |j| {
                        disk.blocks[j] = DiskBlock{ .free = {} };
                    }
                    try disk.file_map.put(file_id, .{ .idx = i, .size = file.size });
                    break;
                }
            }
        }

        if (file_id == 0) break;
        file_id -= 1;
    }

    // printDisk(disk.blocks);

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

const FileMapV = struct {
    idx: usize,
    size: u64,
};

const Disk = struct {
    blocks: []DiskBlock,
    file_map: std.AutoArrayHashMap(u64, FileMapV),
};

fn parseDisk(allocator: std.mem.Allocator, disk_map: []const u8) !Disk {
    var blocks = std.ArrayList(DiskBlock).init(allocator);
    var file_map = std.AutoArrayHashMap(u64, FileMapV).init(allocator);
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
                try file_map.put(file_id, .{ .idx = blocks.items.len - 1, .size = size });
            }
        }
        if (is_file) file_id += 1;
        is_file = !is_file;
    }

    return Disk{ .blocks = try blocks.toOwnedSlice(), .file_map = file_map };
}
