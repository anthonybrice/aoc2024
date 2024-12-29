const std = @import("std");
const util = @import("../main.zig");

const Vec5 = @Vector(5, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    const locks_and_keys = try parseLocksAndKeys(allocator, file_contents);
    const locks = locks_and_keys.locks;
    defer allocator.free(locks);
    const keys = locks_and_keys.keys;
    defer allocator.free(keys);

    var sum: u64 = 0;
    for (locks) |lock| {
        for (keys) |key| {
            if (fit(lock, key)) {
                sum += 1;
            }
        }
    }
    std.debug.print("{d}\n", .{sum});
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
            // parse lock
            const lock = parseLock(in_lines);
            try locks.append(lock);
        } else {
            // parse key
            const key = parseKey(in_lines);
            try keys.append(key);
        }
    }

    return .{ .locks = try locks.toOwnedSlice(), .keys = try keys.toOwnedSlice() };
}

fn parseLock(in: [5][5]u8) Lock {
    var lock: Lock = undefined;
    for (in, 0..) |line, i| {
        var height: i64 = 0;
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
    var key: Lock = undefined;
    for (in, 0..) |line, i| {
        var height: i64 = 5;
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
