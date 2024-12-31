const std = @import("std");
const Allocator = std.mem.Allocator;
const M = std.math.big.int.Managed;

pub const Context = struct {
    allocator: Allocator,
    init_stones: std.ArrayList(M),
    init_stones_: std.ArrayList(u64),

    pub fn deinit(self: *Context) void {
        for (self.init_stones.items) |*item| item.deinit();
        self.init_stones.deinit();
        self.init_stones_.deinit();
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.init_stones = std.ArrayList(M).init(allocator);
    ctx.init_stones_ = std.ArrayList(u64).init(allocator);

    var tokens = std.mem.tokenizeAny(u8, input, " \n");
    while (tokens.next()) |v| {
        const num = try std.fmt.parseInt(u64, v, 10);
        try ctx.init_stones.append(try M.initSet(allocator, num));
        try ctx.init_stones_.append(num);
    }

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var zero = try M.init(ctx.allocator);
    defer zero.deinit();
    var current = ctx.init_stones;
    for (0..25) |i| {
        var next_stones = std.ArrayList(M).init(ctx.allocator);

        for (current.items) |num| {
            if (M.eql(num, zero)) {
                try next_stones.append(try M.initSet(ctx.allocator, 1));
            } else if (try countDigits(ctx.allocator, num) % 2 == 0) {
                const halves = try splitEvenDigits(ctx.allocator, num);
                try next_stones.append(halves[0]);
                try next_stones.append(halves[1]);
            } else {
                var m = try M.initSet(ctx.allocator, 2024);
                defer m.deinit();
                var new = try M.init(ctx.allocator);
                try M.mul(&new, &num, &m);
                try next_stones.append(new);
            }
        }

        if (i != 24) {
            for (current.items) |*item| item.deinit();
            current.deinit();
        }

        current = next_stones;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{current.items.len});
}

fn splitEvenDigits(allocator: std.mem.Allocator, num: M) ![2]M {
    // const digit_count = countDigits(allocator, num);

    var num_string = try num.toString(allocator, 10, std.fmt.Case.lower);
    const digit_count = num_string.len;
    defer allocator.free(num_string);
    const half = digit_count / 2;
    const first_half = num_string[0..half];
    const second_half = num_string[half..digit_count];

    var i = try M.init(allocator);
    try i.setString(10, first_half);
    var j = try M.init(allocator);
    try j.setString(10, second_half);

    return [_]M{ i, j };
}

fn countDigits(allocator: std.mem.Allocator, num: M) !u64 {
    const num_string = try num.toString(allocator, 10, std.fmt.Case.lower);
    defer allocator.free(num_string);
    return num_string.len;
}
