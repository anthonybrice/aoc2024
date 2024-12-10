const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var disk = try Disk.initFromDenseMap(
        allocator,
        std.mem.trimRight(u8, file_contents, "\n"),
    );
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
    std.debug.print("{d}\n", .{sum});
}

pub const Disk = struct {
    allocator: std.mem.Allocator,
    blocks: []Block,
    file_map: std.AutoArrayHashMap(u64, File),

    const Block = union(enum) {
        file: u64,
        free,
    };

    const File = struct {
        idx: usize,
        size: u64,
    };

    pub fn compact(self: *Disk) !void {
        var start = self.blocks.len - 1;
        while (start >= 0) {
            const block = self.blocks[start];
            switch (block) {
                .file => |file| {
                    // find index of first free block
                    var free_idx: usize = undefined;
                    for (0..self.blocks.len) |i| {
                        if (self.blocks[i] == .free) {
                            free_idx = i;
                            break;
                        }
                    }
                    if (free_idx > start) break;
                    self.blocks[free_idx] = Disk.Block{ .file = file };
                    self.blocks[start] = Disk.Block{ .free = {} };
                },
                .free => {},
            }

            if (start == 0) break;
            start -= 1;
        }
    }

    fn isCompacted(self: *Disk) bool {
        var free_block_found = false;
        for (0..self.blocks.len) |i| {
            const block = self.blocks[i];
            switch (block) {
                .file => {
                    if (free_block_found) return false;
                },
                .free => free_block_found = true,
            }
        }

        return true;
    }

    pub fn defrag(self: *Disk) !void {
        var max_file_id: u64 = 0;
        for (self.file_map.keys()) |file_id| {
            if (file_id > max_file_id) max_file_id = file_id;
        }

        var file_id = max_file_id;
        while (file_id >= 0) {
            const file = self.file_map.get(file_id).?;

            // find first free segment in which file will fit
            for (0..file.idx) |i| {
                if (self.blocks[i] == .free) {
                    var size: u64 = 0;
                    for (i..self.blocks.len) |j| {
                        if (self.blocks[j] == .free) {
                            size += 1;
                        } else {
                            break;
                        }
                    }
                    if (size >= file.size) {
                        for (i..i + file.size) |j| {
                            self.blocks[j] = Disk.Block{ .file = file_id };
                        }
                        for (file.idx..file.idx + file.size) |j| {
                            self.blocks[j] = Disk.Block{ .free = {} };
                        }
                        try self.file_map.put(file_id, .{ .idx = i, .size = file.size });
                        break;
                    }
                }
            }

            if (file_id == 0) break;
            file_id -= 1;
        }
    }

    pub fn initFromDenseMap(allocator: std.mem.Allocator, disk_map: []const u8) !Disk {
        var blocks = std.ArrayList(Disk.Block).init(allocator);
        var file_map = std.AutoArrayHashMap(u64, File).init(allocator);
        var is_file = true;
        var file_id: u64 = 0;
        for (disk_map) |char| {
            const size = try std.fmt.parseInt(u64, &[_]u8{char}, 10);
            for (0..size) |i| {
                var block: Disk.Block = undefined;
                if (is_file) {
                    block = Disk.Block{ .file = file_id };
                } else {
                    block = Disk.Block{ .free = {} };
                }
                try blocks.append(block);
                if (is_file and i == 0) {
                    try file_map.put(file_id, .{ .idx = blocks.items.len - 1, .size = size });
                }
            }
            if (is_file) file_id += 1;
            is_file = !is_file;
        }

        return Disk{
            .blocks = try blocks.toOwnedSlice(),
            .file_map = file_map,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Disk) void {
        self.allocator.free(self.blocks);
        self.file_map.deinit();
    }

    pub fn printBlocks(self: Disk) void {
        for (0..self.block.len) |i| {
            const block = self.block[i];
            switch (block) {
                .file => |file| std.debug.print("{d}", .{file}),
                .free => std.debug.print(".", .{}),
            }
        }
        std.debug.print("\n", .{});
    }
};
