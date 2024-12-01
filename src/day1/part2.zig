const std = @import("std");

pub fn main(allocator: std.mem.Allocator, input_file: []const u8) !void {
    var in = try std.fs.cwd().openFile(input_file, .{ .mode = .read_only });
    defer in.close();

    const file_contents = try in.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var left_list = std.ArrayList(u64).init(allocator);
    defer left_list.deinit();
    var right_counts = std.AutoHashMap(u64, u64).init(allocator);
    defer right_counts.deinit();

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const left_token = tokens.next().?;
        const right_token = tokens.next().?;

        const left_int = try std.fmt.parseInt(u64, left_token, 10);
        const right_int = try std.fmt.parseInt(u64, right_token, 10);

        try left_list.append(left_int);
        if (right_counts.get(right_int)) |count| {
            try right_counts.put(right_int, count + 1);
        } else {
            try right_counts.put(right_int, 1);
        }
    }

    std.mem.sort(u64, left_list.items, {}, std.sort.asc(u64));

    var sum: u64 = 0;
    for (left_list.items) |left| {
        const count = right_counts.get(left) orelse 0;
        sum += left * count;
    }

    std.debug.print("{d}\n", .{sum});
}
