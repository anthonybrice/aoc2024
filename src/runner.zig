const std = @import("std");
const Allocator = std.mem.Allocator;
const common = @import("common.zig");
const days = @import("_days.zig");

fn printTime_(t: u64, fmax: comptime_int) void {
    const units = [_][]const u8{ "ns", "µs", "ms", "s" };
    var ui: usize = 0;
    var d = t;
    var r: u64 = 0;
    while (d > fmax) {
        r = (d % 1000) / 100;
        d = d / 1000;
        ui += 1;
    }
    if (fmax == 99) {
        std.debug.print("\t{d:2}.{d} {s}", .{ d, r, units[ui] });
    } else {
        std.debug.print("\t{d}.{d} {s}", .{ d, r, units[ui] });
    }
}

fn printTime(t: u64) void {
    return printTime_(t, 99);
}

fn cmpByLast(ctx: void, a: @Vector(4, u64), b: @Vector(4, u64)) bool {
    return std.sort.asc(u64)(ctx, a[3], b[3]);
}

pub fn runDay(allocator: Allocator, work: common.Worker, single: bool) !u64 {
    const buf = try common.getInput(allocator, work.day);
    defer allocator.free(buf);
    const max_chunks = 100;
    var times = [_]@Vector(4, u64){@splat(0)} ** max_chunks;
    var mid: usize = 0;
    var total_iter: usize = 0;
    var chunk_iter: usize = 10;
    for (0..100) |cnk| {
        std.debug.print("\rday {s}:", .{work.day});
        var task_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer task_arena.deinit();
        var thr_arena = std.heap.ThreadSafeAllocator{
            .child_allocator = task_arena.allocator(),
        };
        const task_allocator = thr_arena.allocator();
        var ctxs = try task_allocator.alloc(*anyopaque, chunk_iter);
        const bufs = try task_allocator.alloc([]u8, chunk_iter);
        for (0..chunk_iter) |i| {
            bufs[i] = try task_allocator.alloc(u8, buf.len);
            @memcpy(bufs[i], buf);
        }
        var t = try std.time.Timer.start();
        for (0..chunk_iter) |i| ctxs[i] = try work.parse(task_allocator, bufs[i]);
        times[cnk][0] = t.read() / chunk_iter;
        printTime(times[cnk][0]);
        t.reset();
        var a1: []const u8 = undefined;
        var a2: []const u8 = undefined;

        for (0..chunk_iter) |i| a1 = try work.part1(ctxs[i]);
        times[cnk][1] = t.read() / chunk_iter;
        printTime(times[cnk][1]);
        t.reset();
        for (0..chunk_iter) |i| a2 = try work.part2(ctxs[i]);
        times[cnk][2] = t.read() / chunk_iter;
        printTime(times[cnk][2]);
        times[cnk][3] = @reduce(.Add, times[cnk]);
        total_iter += chunk_iter;
        if (cnk >= 10) {
            std.mem.sort(@Vector(4, u64), times[0..cnk], {}, cmpByLast);
            const ofs = cnk / 5;
            const tmin = times[ofs][3];
            const tmax = times[cnk - ofs][3];
            const delta = 100 * (tmax - tmin) / (tmax + tmin);
            mid = cnk / 2;
            std.debug.print("\rday {s}:", .{work.day});
            for (0..4) |i| printTime(times[mid][i]);
            std.debug.print(" (+-{d}%) iter={d}    ", .{ delta, total_iter });
            if (delta <= 1) break;
        } else {
            std.debug.print("\rday {s}:", .{work.day});
            for (0..4) |i| printTime(times[mid][i]);
            std.debug.print(" (...{d}) iter={d}    ", .{ 9 - cnk, total_iter });
        }
        if (chunk_iter < 1000 and times[0][3] * chunk_iter < 10000000) chunk_iter *= 10;
        if (single)
            std.debug.print("    p1:[{s}] p2:[{s}]      ", .{ a1, a2 });
    }
    std.debug.print("\n", .{});
    return times[mid][3];
}

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    common.ensurePool(allocator);
    std.debug.print("\tparse\tpart1\tpart2\ttotal\n", .{});

    if (args.len < 2 or std.mem.eql(u8, args[1], "all")) {
        var all: u64 = 0;
        const foo = std.enums.values(days.Day);
        for (foo) |day| {
            all += try runDay(allocator, days.getWork(day), false);
        }
        std.debug.print("\nall days total: ", .{});
        printTime_(all, 999);
        std.debug.print("\n", .{});
    } else {
        const day_str = args[1];
        const day = std.meta.stringToEnum(days.Day, day_str) orelse {
            std.debug.print("Invalid day\n", .{});
            return;
        };
        _ = try runDay(allocator, days.getWork(day), true);
    }

    common.shutdownPool();
}
