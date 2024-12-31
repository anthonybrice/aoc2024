const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    reports: []const []const u64,

    pub fn deinit(self: Context) void {
        for (self.reports) |levels| {
            self.allocator.free(levels);
        }
        self.allocator.free(self.reports);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    var reports = std.ArrayList([]const u64).init(allocator);
    defer reports.deinit();

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        var levels = std.ArrayList(u64).init(allocator);
        defer levels.deinit();
        while (tokens.next()) |t| {
            const n = try std.fmt.parseInt(u64, t, 10);
            try levels.append(n);
        }
        try reports.append(try levels.toOwnedSlice());
    }

    ctx.allocator = allocator;
    ctx.reports = try reports.toOwnedSlice();

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.reports) |levels| {
        if (isIncreasingSafely(levels) or isDecreasingSafely(levels)) {
            sum += 1;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
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
