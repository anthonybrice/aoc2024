const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn part1(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.left, ctx.right) |left, right| {
        sum += @abs(left - right);
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub const Context = struct {
    allocator: Allocator,
    left: []i64,
    right: []i64,

    pub fn deinit(self: Context) void {
        self.allocator.free(self.left);
        self.allocator.free(self.right);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    var left = std.ArrayList(i64).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(i64).init(allocator);
    defer right.deinit();

    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const left_token = tokens.next().?;
        const right_token = tokens.next().?;

        const left_int = try std.fmt.parseInt(i64, left_token, 10);
        const right_int = try std.fmt.parseInt(i64, right_token, 10);

        try left.append(left_int);
        try right.append(right_int);
    }

    std.mem.sort(i64, left.items, {}, std.sort.asc(i64));
    std.mem.sort(i64, right.items, {}, std.sort.asc(i64));

    ctx.allocator = allocator;
    ctx.left = try left.toOwnedSlice();
    ctx.right = try right.toOwnedSlice();

    return ctx;
}
