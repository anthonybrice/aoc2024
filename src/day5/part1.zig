const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    const parsed_file = try parseFile(allocator, file_contents);
    const pairs = parsed_file.pairs;
    defer allocator.free(pairs);
    const sequences = parsed_file.sequences;
    defer {
        for (sequences) |sequence| allocator.free(sequence);
        allocator.free(sequences);
    }

    var sum: u64 = 0;
    for (sequences) |sequence| {
        const filtered_pairs = try filterPairs(allocator, pairs, sequence);
        defer allocator.free(filtered_pairs);
        const ordering = try topologicalSort(allocator, filtered_pairs);
        defer allocator.free(ordering);
        if (std.sort.isSorted(u64, sequence, ordering, lessThan)) {
            const middle_idx = sequence.len / 2;
            const middle_num = sequence[middle_idx];
            sum += middle_num;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

pub fn lessThan(context: []const u64, lhs: u64, rhs: u64) bool {
    const index_lhs = std.mem.indexOf(u64, context, &[_]u64{lhs}).?;
    const index_rhs = std.mem.indexOf(u64, context, &[_]u64{rhs}).?;
    return index_lhs < index_rhs;
}

pub fn parseFile(allocator: std.mem.Allocator, file_contents: []const u8) !Sections {
    var sections = std.mem.tokenizeSequence(u8, file_contents, "\n\n");
    var pairs_lines = std.mem.tokenizeScalar(u8, sections.next().?, '\n');
    var pairs_list = std.ArrayList([2]u64).init(allocator);
    while (pairs_lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, '|');
        const x = try std.fmt.parseInt(u64, tokens.next().?, 10);
        const y = try std.fmt.parseInt(u64, tokens.next().?, 10);
        try pairs_list.append(.{ x, y });
    }

    var sequences_lines = std.mem.tokenizeScalar(u8, sections.next().?, '\n');
    var sequences_list = std.ArrayList([]const u64).init(allocator);
    while (sequences_lines.next()) |line| {
        var tokens = std.mem.tokenizeScalar(u8, line, ',');
        var sequence_list = std.ArrayList(u64).init(allocator);
        while (tokens.next()) |token| {
            const num = try std.fmt.parseInt(u64, token, 10);
            try sequence_list.append(num);
        }
        try sequences_list.append(try sequence_list.toOwnedSlice());
    }

    return .{
        .pairs = try pairs_list.toOwnedSlice(),
        .sequences = try sequences_list.toOwnedSlice(),
    };
}

pub const Sections = struct {
    pairs: []const [2]u64,
    sequences: []const []const u64,
};

pub fn topologicalSort(
    allocator: std.mem.Allocator,
    pairs: []const [2]u64,
) ![]const u64 {
    var graph = std.AutoArrayHashMap(u64, std.ArrayList(u64)).init(allocator);
    defer {
        for (graph.values()) |list| list.deinit();
        graph.deinit();
    }
    var in_degree = std.AutoArrayHashMap(u64, u64).init(allocator);
    defer in_degree.deinit();
    var nodes = std.AutoArrayHashMap(u64, void).init(allocator);
    defer nodes.deinit();

    for (pairs) |pair| {
        const x = pair[0];
        const y = pair[1];

        var list = graph.get(x) orelse std.ArrayList(u64).init(allocator);
        try list.append(y);
        try graph.put(x, list);

        if (in_degree.contains(y)) {
            const degree = in_degree.get(y).?;
            try in_degree.put(y, degree + 1);
        } else {
            try in_degree.put(y, 1);
        }

        if (!in_degree.contains(x)) {
            try in_degree.put(x, 0);
        }

        try nodes.put(x, {});
        try nodes.put(y, {});
    }

    const L = std.DoublyLinkedList(u64);
    var queue = L{};
    for (nodes.keys()) |node| {
        if (in_degree.get(node).? == 0) {
            var new_node = L.Node{ .data = node };
            queue.append(&new_node);
        }
    }
    var topological_order = std.ArrayList(u64).init(allocator);

    while (queue.len != 0) {
        const current: u64 = queue.popFirst().?.*.data;
        try topological_order.append(current);

        if (!graph.contains(current)) continue;

        for (graph.get(current).?.items) |neighbor| {
            const new_in_degree = in_degree.get(neighbor).? - 1;
            try in_degree.put(neighbor, new_in_degree);
            if (new_in_degree == 0) {
                var new_node = L.Node{ .data = neighbor };
                queue.append(&new_node);
            }
        }
    }

    if (topological_order.items.len != nodes.keys().len) {
        topological_order.deinit();
        return error.CycleDetected;
    }

    return topological_order.toOwnedSlice();
}

pub fn filterPairs(
    allocator: std.mem.Allocator,
    pairs: []const [2]u64,
    sequence: []const u64,
) ![]const [2]u64 {
    var filtered = std.ArrayList([2]u64).init(allocator);
    for (pairs) |pair| {
        if (std.mem.containsAtLeast(u64, sequence, 1, &[_]u64{pair[0]}) and
            std.mem.containsAtLeast(u64, sequence, 1, &[_]u64{pair[1]}))
        {
            try filtered.append(pair);
        }
    }
    return filtered.toOwnedSlice();
}

test "expect topological sort to detect cycle" {
    const allocator = std.testing.allocator;
    const result = topologicalSort(
        allocator,
        &[_][2]u64{ .{ 1, 2 }, .{ 2, 1 } },
    );
    try std.testing.expect(result == error.CycleDetected);
}

test "expect topological sort to sort" {
    const allocator = std.testing.allocator;
    const result = try topologicalSort(
        allocator,
        &[_][2]u64{ .{ 1, 2 }, .{ 2, 3 } },
    );
    defer allocator.free(result);
    try std.testing.expect(std.mem.eql(u64, result, &[_]u64{ 1, 2, 3 }));
}
