const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    in: []const u8,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.in);
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;

    const new_in = try allocator.alloc(u8, input.len);
    @memcpy(new_in, input);
    ctx.in = new_in;

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    var adjs = try mkAdjs(allocator, ctx.in);
    defer {
        for (adjs.values()) |v| {
            v.deinit();
        }
        adjs.deinit();
    }
    const trios = try findAllTrios(allocator, adjs);
    defer trios.deinit();

    var sum: u64 = 0;
    for (trios.items) |trio| {
        if (maybeHistorian(trio)) {
            sum += 1;
        }
    }

    return std.fmt.allocPrint(allocator, "{d}", .{sum});
}

fn mkAdjs(allocator: std.mem.Allocator, input: []const u8) !std.StringArrayHashMap(std.ArrayList([]const u8)) {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var adjs = std.StringArrayHashMap(std.ArrayList([]const u8)).init(allocator);

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, '-');
        const c1 = tokens.next().?;
        const c2 = tokens.next().?;
        var v1 = adjs.get(c1) orelse std.ArrayList([]const u8).init(allocator);
        var v2 = adjs.get(c2) orelse std.ArrayList([]const u8).init(allocator);
        try v1.append(c2);
        try v2.append(c1);
        try adjs.put(c1, v1);
        try adjs.put(c2, v2);
    }

    return adjs;
}

fn findAllTrios(allocator: std.mem.Allocator, adjs: std.StringArrayHashMap(std.ArrayList([]const u8))) !std.ArrayList([3][]const u8) {
    var trios = std.ArrayList([3][]const u8).init(allocator);
    defer trios.deinit();

    for (adjs.keys()) |node| {
        const neighbors = adjs.get(node).?.items;
        for (0..neighbors.len) |i| {
            const neighbor1 = neighbors[i];
            for (i + 1..neighbors.len) |j| {
                const neighbor2 = neighbors[j];
                if (isConnected(adjs, neighbor1, neighbor2)) {
                    try trios.append([3][]const u8{ node, neighbor1, neighbor2 });
                }
            }
        }
    }

    var trios_final = std.ArrayList([3][]const u8).init(allocator);
    for (trios.items) |k2| {
        var insert = true;
        for (trios_final.items) |k1| {
            if (trioEql(k1, k2)) {
                insert = false;
                break;
            }
        }
        if (insert) {
            try trios_final.append(k2);
        }
    }

    return trios_final;
}

fn trioEql(k1: [3][]const u8, k2: [3][]const u8) bool {
    return contains(k1, k2[0]) and contains(k1, k2[1]) and contains(k1, k2[2]);
}

fn contains(trio: [3][]const u8, node: []const u8) bool {
    for (trio) |n| {
        if (std.mem.eql(u8, n, node)) {
            return true;
        }
    }
    return false;
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn isConnected(adjs: std.StringArrayHashMap(std.ArrayList([]const u8)), node1: []const u8, node2: []const u8) bool {
    const neighbors = adjs.get(node1) orelse return false;
    for (neighbors.items) |neighbor| {
        if (std.mem.eql(u8, neighbor, node2)) {
            return true;
        }
    }
    return false;
}

fn maybeHistorian(t: [3][]const u8) bool {
    return t[0][0] == 't' or t[1][0] == 't' or t[2][0] == 't';
}
