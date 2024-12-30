const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Worker = struct {
    day: []const u8,
    parse: *const fn (allocator: Allocator, in: []const u8) anyerror!*anyopaque,
    part1: *const fn (ctx: *anyopaque) anyerror![]const u8,
    part2: *const fn (ctx: *anyopaque) anyerror![]const u8,
};

pub var pool: std.Thread.Pool = undefined;
pub var pool_running = false;
pub var pool_allocator: Allocator = undefined;
pub var pool_arena: std.heap.ThreadSafeAllocator = undefined;

pub fn ensurePool(allocator: Allocator) void {
    if (!pool_running) {
        pool_arena = .{
            .child_allocator = allocator,
        };
        pool_allocator = pool_arena.allocator();
        pool.init(std.Thread.Pool.Options{ .allocator = pool_allocator }) catch {
            std.debug.panic("failed to init pool\n", .{});
        };
        pool_running = true;
    }
}

pub fn shutdownPool() void {
    if (pool_running) {
        pool.deinit();
        pool_running = false;
    }
}

pub fn downloadFile(allocator: Allocator, url: []const u8, path: []const u8, cookie: ?[]const u8) !void {
    std.debug.print("Trying to download {s} from {s}\n", .{ path, url });
    var http_client = std.http.Client{ .allocator = allocator };
    defer http_client.deinit();
    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();
    const res = try http_client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .response_storage = .{ .dynamic = &response },
        .extra_headers = &[_]std.http.Header{.{
            .name = "Cookie",
            .value = cookie orelse "",
        }},
    });
    if (res.status != .ok) {
        std.debug.panic("Failed to fetch input file: {d}\n", .{res.status});
        return error.FailedToFetchInputFile;
    }
    const dir = try std.fs.cwd().makeOpenPath(std.fs.path.dirname(path).?, .{});
    const file = try dir.createFile(std.fs.path.basename(path), .{});
    defer file.close();
    try file.writeAll(response.items);
}

pub fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    var in = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer in.close();

    return try in.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub fn getInput(allocator: Allocator, day: []const u8) ![]const u8 {
    const filename = try std.fmt.allocPrint(allocator, "in/day{s}.txt", .{day});
    defer allocator.free(filename);
    std.fs.cwd().access(filename, .{}) catch |err| {
        if (err == error.FileNotFound) {
            var buf = [_]u8{0} ** 1024;
            const cookie = std.fs.cwd().readFile(".cookie", &buf) catch |e| {
                std.debug.panic("Error reading .cookie: {any}\n", .{e});
            };
            const url = try std.fmt.allocPrint(
                allocator,
                "https://adventofcode.com/2024/day/{s}/input",
                .{day},
            );
            defer allocator.free(url);
            try downloadFile(allocator, url, filename, cookie);
        }
    };
    return try readFile(allocator, filename);
}

pub fn runDay(work: Worker) !void {
    const gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.debug.print("Memory leak detected\n", .{});
    }
    const allocator = gpa.allocator();
    const input = try getInput(allocator, work.day);
    const ctx = work.parse(allocator, input);
    std.debug.print("{s}\n", .{work.part1(ctx)});
    std.debug.print("{s}\n", .{work.part2(ctx)});
}
