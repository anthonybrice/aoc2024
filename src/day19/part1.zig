const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    towel_patterns: []const []const u8,
    towels: []const []const u8,

    pub fn deinit(self: *Context) void {
        for (self.towel_patterns) |pattern| {
            self.allocator.free(pattern);
        }
        self.allocator.free(self.towel_patterns);
        for (self.towels) |towel| {
            self.allocator.free(towel);
        }
        self.allocator.free(self.towels);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    ctx.towel_patterns = try parseAvailablePatterns(allocator, lines.next().?);

    var towels = std.ArrayList([]const u8).init(allocator);
    defer towels.deinit();
    while (lines.next()) |towel| {
        const new_towel = try allocator.alloc(u8, towel.len);
        @memcpy(new_towel, towel);
        try towels.append(new_towel);
    }

    ctx.towels = try towels.toOwnedSlice();

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var memo = std.StringHashMap(bool).init(ctx.allocator);
    defer memo.deinit();

    var sum: u64 = 0;
    for (ctx.towels) |towel| {
        if (try isPossible(
            towel,
            ctx.towel_patterns,
            &memo,
        )) {
            sum += 1;
        }
    }

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn parseAvailablePatterns(allocator: std.mem.Allocator, in: []const u8) ![]const []const u8 {
    var tokens = std.mem.tokenizeSequence(u8, in, ", ");
    var towel_patterns = std.ArrayList([]const u8).init(allocator);
    defer towel_patterns.deinit();

    while (tokens.next()) |token| {
        const new_pattern = try allocator.alloc(u8, token.len);
        @memcpy(new_pattern, token);
        try towel_patterns.append(new_pattern);
    }

    return towel_patterns.toOwnedSlice();
}

fn isPossible(
    towel: []const u8,
    towel_patterns: []const []const u8,
    memo: *std.StringHashMap(bool),
) !bool {
    if (towel.len == 0) {
        return true;
    }

    if (memo.get(towel)) |result| {
        return result;
    }

    for (towel_patterns) |pattern| {
        if (std.mem.startsWith(u8, towel, pattern)) {
            const remaining_towel = towel[pattern.len..];
            if (try isPossible(remaining_towel, towel_patterns, memo)) {
                try memo.put(towel, true);
                return true;
            }
        }
    }

    try memo.put(towel, false);
    return false;
}
