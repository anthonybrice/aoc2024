const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    init_ns: []i64,

    pub fn deinit(self: Context) void {
        self.allocator.free(self.init_ns);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    var init_ns = std.ArrayList(i64).init(allocator);
    defer init_ns.deinit();
    var lines = std.mem.tokenizeScalar(u8, in, '\n');
    while (lines.next()) |line| {
        const n = try std.fmt.parseInt(i64, line, 10);
        try init_ns.append(n);
    }
    ctx.init_ns = try init_ns.toOwnedSlice();
    ctx.allocator = allocator;

    return ctx;
}

pub fn part2(ctx: *Context) ![]const u8 {
    // a map of the total bananas for each 4-price-change sequence
    var market = std.AutoArrayHashMap(i64, i64).init(ctx.allocator);
    defer market.deinit();
    // a map of 4-price-change sequences to each buyer's index
    var buyers = std.AutoArrayHashMap(i64, usize).init(ctx.allocator);
    defer buyers.deinit();

    try makeMarket(ctx.allocator, ctx.init_ns, &market, &buyers);
    var max_bananas: i64 = 0;
    for (market.values()) |v| {
        if (v > max_bananas) {
            max_bananas = v;
        }
    }

    return std.fmt.allocPrint(ctx.allocator, "{d}", .{max_bananas});
}

fn makeMarket(
    allocator: Allocator,
    init_ns: []i64,
    market: *std.AutoArrayHashMap(i64, i64),
    buyers: *std.AutoArrayHashMap(i64, usize),
) !void {
    for (init_ns, 0..) |n, i| {
        try addBuyerPrices(allocator, i, n, buyers, market);
    }
}

fn addBuyerPrices(
    allocator: Allocator,
    buyer: usize,
    n: i64,
    buyers: *std.AutoArrayHashMap(i64, usize),
    market: *std.AutoArrayHashMap(i64, i64),
) !void {
    var last_price = @mod(n, 10);
    var changes = std.ArrayList(i64).init(allocator);
    defer changes.deinit();

    var curr = n;
    for (0..2000) |_| {
        curr = nextSecretNumber(curr);
        const price = @mod(curr, 10);
        const change = price - last_price;
        last_price = price;
        try changes.append(change);
        if (changes.items.len < 4) {
            continue;
        } else if (changes.items.len > 4) {
            _ = changes.orderedRemove(0);
        }

        const index = getIndex(
            changes.items[0],
            changes.items[1],
            changes.items[2],
            changes.items[3],
        );
        if (buyers.get(index) == buyer) continue;

        try buyers.put(index, buyer);
        const total = market.get(index) orelse 0;
        try market.put(index, total + price);
    }
}

fn getIndex(a: i64, b: i64, c: i64, d: i64) i64 {
    return (19 * 19 * 19 * (a + 9)) + (19 * 19 * (b + 9)) + (19 * (c + 9)) + (d + 9);
}

pub fn nextSecretNumber(n: i64) i64 {
    const n1 = n * 64;
    const n2 = n1 ^ n;
    const n3 = @mod(n2, 16777216);
    const n4 = @divTrunc(n3, 32);
    const n5 = n4 ^ n3;
    const n6 = @mod(n5, 16777216);
    const n7 = n6 * 2048;
    const n8 = n7 ^ n6;
    const n9 = @mod(n8, 16777216);

    return n9;
}
