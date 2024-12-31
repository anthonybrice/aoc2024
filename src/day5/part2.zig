const std = @import("std");
const p1 = @import("./part1.zig");
const Context = p1.Context;

pub fn part2(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.sections.sequences) |sequence| {
        const filtered_pairs = try p1.filterPairs(
            ctx.allocator,
            ctx.sections.pairs,
            sequence,
        );
        defer ctx.allocator.free(filtered_pairs);
        const ordering = try p1.topologicalSort(ctx.allocator, filtered_pairs);
        defer ctx.allocator.free(ordering);

        if (!std.sort.isSorted(u64, sequence, ordering, p1.lessThan)) {
            const arr_copy = try ctx.allocator.alloc(u64, sequence.len);
            defer ctx.allocator.free(arr_copy);
            @memcpy(arr_copy, sequence);
            std.mem.sort(u64, arr_copy, ordering, p1.lessThan);
            const middle_idx = arr_copy.len / 2;
            const middle_num = arr_copy[middle_idx];
            sum += middle_num;
        }
    }
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}
