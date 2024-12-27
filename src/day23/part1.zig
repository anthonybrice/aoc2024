const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var adjs = try parse(allocator, file_contents);
    defer {
        for (adjs.values()) |v| {
            v.deinit();
        }
        adjs.deinit();
    }

    const trios = try findAllTrios(allocator, adjs);
    defer trios.deinit();

    // for (trios.items) |trio| {
    //     std.debug.print("Trio: {s}, {s}, {s}\n", .{ trio[0], trio[1], trio[2] });
    // }

    var sum: u64 = 0;
    for (trios.items) |trio| {
        if (maybeHistorian(trio)) {
            sum += 1;
        }
    }
    std.debug.print("{}\n", .{sum});
}

fn parse(allocator: std.mem.Allocator, input: []const u8) !std.StringArrayHashMap(std.ArrayList([]const u8)) {
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
