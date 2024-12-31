const std = @import("std");
const Context = @import("part1.zig").Context;
const util = @import("../main.zig");
const p1 = @import("part1.zig");

const Vec2 = @Vector(2, i64);

pub fn part2(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    var lines = std.mem.tokenizeScalar(u8, ctx.in, '\n');

    var sum: u64 = 0;
    while (lines.next()) |line| {
        sum += try complexity(allocator, line, 25);
    }

    return std.fmt.allocPrint(allocator, "{d}", .{sum});
}

fn complexity(
    allocator: std.mem.Allocator,
    code: []const u8,
    n: u64,
) !u64 {
    var num_pad = try p1.Pad.numPad(allocator);
    defer num_pad.deinit();
    var dir_pad = try p1.Pad.dirPad(allocator);
    defer dir_pad.deinit();

    var f_tables = std.ArrayList(std.StringArrayHashMap(u64)).init(allocator);
    defer {
        for (f_tables.items) |*f_table| {
            for (f_table.keys()) |k| {
                allocator.free(k);
            }
            f_table.deinit();
        }
        f_tables.deinit();
    }

    var np_path = std.ArrayList(u8).init(allocator);
    defer np_path.deinit();
    for (code) |c| {
        const seq = try num_pad.push(c);
        defer allocator.free(seq);
        try np_path.appendSlice(seq);
    }
    var m = std.StringArrayHashMap(u64).init(allocator);
    try m.put(try np_path.toOwnedSlice(), 1);
    try f_tables.append(m);

    for (0..n) |_| {
        var new_f_tables = std.ArrayList(std.StringArrayHashMap(u64)).init(allocator);
        for (f_tables.items) |*f_table| {
            var sub_f_table = std.StringArrayHashMap(u64).init(allocator);
            for (f_table.keys()) |seq| {
                const freq = f_table.get(seq).?;
                var sub_map = try seqCounts(allocator, seq, &dir_pad);
                defer {
                    for (sub_map.keys()) |k| {
                        allocator.free(k);
                    }
                    sub_map.deinit();
                }
                for (sub_map.keys()) |sub_seq| {
                    const sub_freq = sub_map.get(sub_seq).?;
                    if (sub_f_table.get(sub_seq)) |sub_table_freq| {
                        try sub_f_table.put(sub_seq, sub_table_freq + sub_freq * freq);
                    } else {
                        const copy = try allocator.alloc(u8, sub_seq.len);
                        @memcpy(copy, sub_seq);
                        try sub_f_table.put(copy, sub_freq * freq);
                    }
                }
            }
            try new_f_tables.append(sub_f_table);
        }
        for (f_tables.items) |*f_table| {
            for (f_table.keys()) |k| {
                allocator.free(k);
            }
            f_table.deinit();
        }
        f_tables.deinit();
        f_tables = new_f_tables;
    }

    var cmplx: u64 = 0;
    for (f_tables.items) |f_table| {
        for (f_table.keys()) |seq| {
            const freq = f_table.get(seq).?;
            cmplx += freq * seq.len;
        }
    }

    const num: u64 = try std.fmt.parseInt(u64, code[0 .. code.len - 1], 10);
    return cmplx * num;
}

fn seqCounts(allocator: std.mem.Allocator, seq: []const u8, pad: *p1.Pad) !std.StringArrayHashMap(u64) {
    var m = std.StringArrayHashMap(u64).init(allocator);

    const seqs = try sequences(allocator, seq, pad);
    defer {
        for (seqs) |s| {
            allocator.free(s);
        }
        allocator.free(seqs);
    }
    for (seqs) |s| {
        if (m.get(s)) |freq| {
            try m.put(s, freq + 1);
        } else {
            const copy = try allocator.alloc(u8, s.len);
            @memcpy(copy, s);
            try m.put(copy, 1);
        }
    }

    return m;
}

fn sequences(allocator: std.mem.Allocator, seq: []const u8, pad: *p1.Pad) ![]const []const u8 {
    var path = std.ArrayList([]const u8).init(allocator);
    for (seq) |c| {
        const instrs = try pad.push(c);
        try path.append(instrs);
    }

    return path.toOwnedSlice();
}
