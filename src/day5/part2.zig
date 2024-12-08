const std = @import("std");
const util = @import("../main.zig");
const d5p1 = @import("./part1.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    const parsed_file = try d5p1.parseFile(allocator, file_contents);
    const pairs = parsed_file.pairs;
    defer allocator.free(pairs);
    const sequences = parsed_file.sequences;
    defer {
        for (sequences) |sequence| allocator.free(sequence);
        allocator.free(sequences);
    }

    var sum: u64 = 0;
    for (sequences) |sequence| {
        const filtered_pairs = try d5p1.filterPairs(allocator, pairs, sequence);
        defer allocator.free(filtered_pairs);
        const ordering = try d5p1.topologicalSort(allocator, filtered_pairs);
        defer allocator.free(ordering);

        if (!std.sort.isSorted(u64, sequence, ordering, d5p1.lessThan)) {
            const arr_copy = try allocator.alloc(u64, sequence.len);
            defer allocator.free(arr_copy);
            @memcpy(arr_copy, sequence);
            std.mem.sort(u64, arr_copy, ordering, d5p1.lessThan);
            const middle_idx = arr_copy.len / 2;
            const middle_num = arr_copy[middle_idx];
            sum += middle_num;
        }
    }
    std.debug.print("{d}\n", .{sum});
}
