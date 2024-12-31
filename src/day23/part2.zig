const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;
const graph = @import("graph.zig");
const tarjan = @import("tarjan.zig");

pub fn part2(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    const r = try mkGraph(allocator, ctx.in);
    var g = r.g;
    defer g.deinit();
    var vs = r.vs;
    defer vs.deinit();

    var cliques = try bronKerbosch(allocator, g, vs);
    defer {
        for (cliques.items) |*v| {
            v.deinit();
        }
        cliques.deinit();
    }

    var len: usize = 0;
    var sg_nodes: std.StringArrayHashMap(void) = undefined;
    for (cliques.items) |v| {
        if (v.count() > len) {
            len = v.count();
            sg_nodes = v;
        }
    }

    var strings_list = std.ArrayList([]const u8).init(allocator);
    defer strings_list.deinit();
    for (sg_nodes.keys()) |k| {
        try strings_list.append(k);
    }
    const strings = try strings_list.toOwnedSlice();
    defer allocator.free(strings);
    std.sort.insertion([]const u8, strings, {}, compareStrings);
    var out = std.ArrayList(u8).init(allocator);
    for (strings) |s| {
        try out.appendSlice(s);
        try out.append(',');
    }
    _ = out.pop();

    return try out.toOwnedSlice();
}

const Graph = graph.DirectedGraph([]const u8, std.hash_map.StringContext);

fn mkGraph(allocator: std.mem.Allocator, input: []const u8) !struct { g: Graph, vs: std.StringArrayHashMap(void) } {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var g = Graph.init(allocator);
    var vs = std.StringArrayHashMap(void).init(allocator);

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, '-');
        const c1 = tokens.next().?;
        const c2 = tokens.next().?;

        try g.add(c1);
        try g.add(c2);
        try g.addEdge(c1, c2, 1);
        try g.addEdge(c2, c1, 1);

        try vs.put(c1, {});
        try vs.put(c2, {});
    }

    return .{ .g = g, .vs = vs };
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn bronKerbosch(allocator: std.mem.Allocator, g: Graph, vs: std.StringArrayHashMap(void)) !std.ArrayList(std.StringArrayHashMap(void)) {
    var acc = std.ArrayList(std.StringArrayHashMap(void)).init(allocator);

    var r = std.StringArrayHashMap(void).init(allocator);
    defer r.deinit();
    var p = try vs.clone();
    defer p.deinit();
    var x = std.StringArrayHashMap(void).init(allocator);
    defer x.deinit();

    try bronKerboschPrime(allocator, g, r, p, x, &acc);

    return acc;
}

fn bronKerboschPrime(
    allocator: std.mem.Allocator,
    g: Graph,
    r: std.StringArrayHashMap(void),
    p: std.StringArrayHashMap(void),
    x: std.StringArrayHashMap(void),
    acc: *std.ArrayList(std.StringArrayHashMap(void)),
) !void {
    if (p.count() == 0 and x.count() == 0) {
        try acc.append(try r.clone());
    }

    var p1 = try p.clone();
    defer p1.deinit();
    var x1 = try x.clone();
    defer x1.deinit();

    for (p.keys()) |v| {
        var r2 = try r.clone();
        defer r2.deinit();
        try r2.put(v, {});
        var v_ns = try getNeighbors(allocator, g, v);
        defer v_ns.deinit();
        var p2 = try intersection(allocator, p1, v_ns);
        defer p2.deinit();
        var x2 = try intersection(allocator, x1, v_ns);
        defer x2.deinit();
        try bronKerboschPrime(allocator, g, r2, p2, x2, acc);

        _ = p1.orderedRemove(v);
        try x1.put(v, {});
    }
}

fn getNeighbors(allocator: std.mem.Allocator, g: Graph, node: []const u8) !std.StringArrayHashMap(void) {
    var neighbors = std.StringArrayHashMap(void).init(allocator);

    const adj_map = g.adjOut.get(g.ctx.hash(node)).?;
    var iter = adj_map.keyIterator();

    while (iter.next()) |h| {
        const v = g.lookup(h.*).?;
        try neighbors.put(v, {});
    }

    return neighbors;
}

fn intersection(allocator: std.mem.Allocator, a: std.StringArrayHashMap(void), b: std.StringArrayHashMap(void)) !std.StringArrayHashMap(void) {
    var result = std.StringArrayHashMap(void).init(allocator);

    for (a.keys()) |k| {
        if (b.contains(k)) {
            try result.put(k, {});
        }
    }

    return result;
}
