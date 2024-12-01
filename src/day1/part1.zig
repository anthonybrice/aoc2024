const std = @import("std");

pub fn main(allocator: std.mem.Allocator, input_file: []const u8) !void {
    var in = try std.fs.cwd().openFile(input_file, .{ .mode = .read_only });
    defer in.close();

    const file_contents = try in.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var left_list = std.ArrayList(u64).init(allocator);
    defer left_list.deinit();
    var right_list = std.ArrayList(u64).init(allocator);
    defer right_list.deinit();

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const left_token = tokens.next().?;
        const right_token = tokens.next().?;

        const left_int = try std.fmt.parseInt(u64, left_token, 10);
        const right_int = try std.fmt.parseInt(u64, right_token, 10);

        try left_list.append(left_int);
        try right_list.append(right_int);
    }

    std.mem.sort(u64, left_list.items, {}, std.sort.asc(u64));
    std.mem.sort(u64, right_list.items, {}, std.sort.asc(u64));

    var sum: u64 = 0;
    for (left_list.items, right_list.items) |left, right| {
        const diff = if (left > right) left - right else right - left;
        sum += diff;
    }

    std.debug.print("{d}\n", .{sum});
}
