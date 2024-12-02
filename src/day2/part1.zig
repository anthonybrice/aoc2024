const std = @import("std");

pub fn main(allocator: std.mem.Allocator, input_file: []const u8) !void {
    var in = try std.fs.cwd().openFile(input_file, .{ .mode = .read_only });
    defer in.close();

    const file_contents = try in.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    var reports = std.mem.tokenizeSequence(u8, file_contents, "\n");

    var sum: u64 = 0;
    while (reports.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        var levels = std.ArrayList(u64).init(allocator);
        // defer levels.deinit();

        while (tokens.next()) |token| {
            const level = try std.fmt.parseInt(u64, token, 10);
            try levels.append(level);
        }

        const levels_slice = try levels.toOwnedSlice();
        defer allocator.free(levels_slice);
        if (isIncreasingSafely(levels_slice) or isDecreasingSafely(levels_slice)) {
            sum += 1;
        }
    }

    std.debug.print("{d}\n", .{sum});
}

pub fn isIncreasingSafely(levels: []const u64) bool {
    if (levels.len < 2) return false;

    for (levels[1..], 1..levels.len) |level, i| {
        const prev_level = levels[i - 1];
        if (prev_level >= level) {
            return false;
        }
        const diff = level - prev_level;

        if (prev_level >= level) {
            return false;
        }

        if (diff < 1 or diff > 3) {
            return false;
        }
    }

    return true;
}

pub fn isDecreasingSafely(levels: []const u64) bool {
    if (levels.len < 2) return false;

    for (levels[1..], 1..levels.len) |level, i| {
        const prev_level = levels[i - 1];
        if (prev_level <= level) {
            return false;
        }
        const diff = prev_level - level;

        if (diff < 1 or diff > 3) {
            return false;
        }
    }

    return true;
}
