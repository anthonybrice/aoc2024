const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../main.zig");

const Vec5 = @Vector(5, u8);

pub const Context: type = struct {
    allocator: Allocator,
    keys: []Key,
    locks: []Lock,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.keys);
        self.allocator.free(self.locks);
        self.allocator.destroy(self);
    }
};

// pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
//     const file_contents = try util.readFile(allocator, filepath);
//     defer allocator.free(file_contents);

//     const locks_and_keys = try parseLocksAndKeys(allocator, file_contents);
//     const locks = locks_and_keys.locks;
//     defer allocator.free(locks);
//     const keys = locks_and_keys.keys;
//     defer allocator.free(keys);

//     var sum: u64 = 0;
//     for (locks) |lock| {
//         for (keys) |key| {
//             if (fit(lock, key)) {
//                 sum += 1;
//             }
//         }
//     }
//     std.debug.print("{d}\n", .{sum});
// }

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    const locks_and_keys = try parseLocksAndKeys(allocator, in);

    ctx.allocator = allocator;
    ctx.keys = locks_and_keys.keys;
    ctx.locks = locks_and_keys.locks;

    return ctx;
}

pub fn part1(ctx: Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.locks) |lock| {
        for (ctx.keys) |key| {
            if (fit(lock, key)) {
                sum += 1;
            }
        }
    }
    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

pub fn part2(_: Context) ![]const u8 {
    return "Merry Christmas!";
}

const Lock = Vec5;

const Key = Vec5;

fn parseLocksAndKeys(allocator: std.mem.Allocator, in: []const u8) !struct { locks: []Lock, keys: []Key } {
    var locks = std.ArrayList(Lock).init(allocator);
    defer locks.deinit();
    var keys = std.ArrayList(Key).init(allocator);
    defer keys.deinit();
    var locks_and_keys = std.mem.tokenizeSequence(u8, in, "\n\n");

    while (locks_and_keys.next()) |x| {
        var lines = std.mem.tokenizeScalar(u8, x, '\n');
        const line0 = lines.next().?;
        var in_lines: [5][5]u8 = undefined;
        for (0..in_lines.len) |i| {
            const line = lines.next().?;
            for (0..line.len) |j| {
                in_lines[j][i] = line[j];
            }
        }
        if (line0[0] == '#') {
            const lock = parseLock(in_lines);
            try locks.append(lock);
        } else {
            const key = parseKey(in_lines);
            try keys.append(key);
        }
    }

    return .{ .locks = try locks.toOwnedSlice(), .keys = try keys.toOwnedSlice() };
}

fn parseLock(in: [5][5]u8) Lock {
    var lock: Lock = undefined;
    for (in, 0..) |line, i| {
        var height: u8 = 0;
        for (line) |c| {
            if (c == '#') {
                height += 1;
            } else {
                break;
            }
        }
        lock[i] = height;
    }

    return lock;
}

fn parseKey(in: [5][5]u8) Key {
    var key: Key = undefined;
    for (in, 0..) |line, i| {
        var height: u8 = 5;
        for (line) |c| {
            if (c == '.') {
                height -= 1;
            } else {
                break;
            }
        }
        key[i] = height;
    }

    return key;
}

fn fit(lock: Lock, key: Key) bool {
    const sum = lock + key;
    const result = sum <= @as(Vec5, @splat(5));

    return @reduce(.And, result);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const path = "in/day25.txt";

    var in = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer in.close();

    const file_contents = try in.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    const ctx = try parse(allocator, file_contents);
    defer ctx.deinit();
    const r = try part1(ctx.*);
    defer allocator.free(r);
    std.debug.print("{s}\n", .{r});
}
