const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');

    var num_pad = try NumPad.init(allocator);
    defer num_pad.deinit();
    var dir_pad1 = try DirPad.init(allocator);
    defer dir_pad1.deinit();
    var dir_pad2 = try DirPad.init(allocator);
    defer dir_pad2.deinit();

    var sum: usize = 0;
    while (lines.next()) |line| {
        const seq = try shortestSequence(
            allocator,
            line,
            &num_pad,
            &dir_pad1,
            &dir_pad2,
        );
        defer allocator.free(seq);
        std.debug.print("{s}\n", .{seq});

        const num: usize = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);
        std.debug.print("{d} * {d} = {d}\n", .{ seq.len, num, (seq.len - 2) * num });
        sum += (seq.len) * num;
    }
    std.debug.print("{d}\n", .{sum});

    // const seq = try shortestSequence(allocator, lines.next().?);
    // defer allocator.free(seq);
    // std.debug.print("{s}\n", .{seq});
    // std.debug.print("{d}\n", .{seq.len - 2});
}

fn shortestSequence(
    allocator: std.mem.Allocator,
    code: []const u8,
    num_pad: *NumPad,
    dir_pad1: *DirPad,
    dir_pad2: *DirPad,
) ![]const u8 {
    // var num_pad = try NumPad.init(allocator);
    // defer num_pad.deinit();
    // var dir_pad1 = try DirPad.init(allocator);
    // defer dir_pad1.deinit();
    // var dir_pad2 = try DirPad.init(allocator);
    // defer dir_pad2.deinit();

    var sequence = std.ArrayList(u8).init(allocator);
    defer sequence.deinit();
    for (code) |c| {
        const np_path = try num_pad.push(c);
        defer allocator.free(np_path);
        std.debug.print("char: {c}, path: {s}\n", .{ c, np_path });

        var d1_path = std.ArrayList(u8).init(allocator);
        defer d1_path.deinit();
        for (np_path) |k| {
            const dir1_instrs = try dir_pad1.push(k);
            // std.debug.print("dir1: key: {c}, path: {s}\n", .{ k, dir1_instrs });
            defer allocator.free(dir1_instrs);
            try d1_path.appendSlice(dir1_instrs);
        }
        std.debug.print("char: {c}, d1_path: {s}\n", .{ c, d1_path.items });

        var d2_path = std.ArrayList(u8).init(allocator);
        defer d2_path.deinit();
        for (d1_path.items) |k| {
            const dir2_instrs = try dir_pad2.push(k);
            // std.debug.print("dir2: key: {c}, path: {s}\n", .{ k, dir2_instrs });
            defer allocator.free(dir2_instrs);
            try d2_path.appendSlice(dir2_instrs);
        }
        std.debug.print("char: {c}, d2_path: {s}\n", .{ c, d2_path.items });
        try sequence.appendSlice(d2_path.items);
        // std.debug.print("\n", .{});
    }

    return sequence.toOwnedSlice();
}

fn toString(allocator: std.mem.Allocator, instrs: []const Vec2) ![]const u8 {
    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();
    for (instrs) |dir| {
        if (std.meta.eql(dir, .{ -1, 0 })) {
            try str.append('^');
        } else if (std.meta.eql(dir, .{ 1, 0 })) {
            try str.append('v');
        } else if (std.meta.eql(dir, .{ 0, -1 })) {
            try str.append('<');
        } else if (std.meta.eql(dir, .{ 0, 1 })) {
            try str.append('>');
        } else {
            return error.InvalidCharacter;
        }
    }
    try str.append('A');

    return str.toOwnedSlice();
}

fn Pad(pad_map: std.AutoArrayHashMap(Vec2, u8)) type {
    return struct {
        allocator: std.mem.Allocator,
        pad_map: std.AutoArrayHashMap(Vec2, u8),
        inverse_map: std.AutoArrayHashMap(u8, Vec2),
        arm: Vec2,

        pub fn init(allocator: std.mem.Allocator) !Pad {
            var inverse_map = std.AutoArrayHashMap(u8, Vec2).init(allocator);
            for (pad_map.keys()) |k| {
                const v = pad_map.get(k).?;
                try inverse_map.put(v, k);
            }
            return @This(){
                .allocator = allocator,
                .pad_map = pad_map,
                .inverse_map = inverse_map,
                .arm = try findChar(pad_map, 'A'),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.pad_map.deinit();
            self.inverse_map.deinit();
        }

        pub fn push(self: *@This(), key: u8) ![]const u8 {
            const pos = self.inverse_map.get(key).?;

            const path = try aStar(self.allocator, self.keys, self.arm, pos);
            // std.debug.print("path from aStar: {any}\n", .{path});
            defer self.allocator.free(path);
            self.arm = pos;

            const dirs = try dirsFromPath(self.allocator, path);
            defer self.allocator.free(dirs);

            return toString(self.allocator, dirs);
        }

        pub fn do(self: *NumPad, x: []const u8) ![]const u8 {
            var y = std.ArrayList(u8).init(self.allocator);
            defer y.deinit();
            for (x) |c| {
                if (c == '^') {
                    self.arm += Vec2{ -1, 0 };
                } else if (c == 'v') {
                    self.arm += Vec2{ 1, 0 };
                } else if (c == '<') {
                    self.arm += Vec2{ 0, -1 };
                } else if (c == '>') {
                    self.arm += Vec2{ 0, 1 };
                } else if (c == 'A') {
                    try y.append(self.keys.get(self.arm).?);
                } else {
                    return error.InvalidCharacter;
                }
            }

            return y.toOwnedSlice();
        }

        fn findChar(maze: std.AutoArrayHashMap(Vec2, u8), char: u8) !Vec2 {
            var iter = maze.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.* == char) {
                    return entry.key_ptr.*;
                }
            }
            return error.NotFound;
        }
    };
}

const NumPad = struct {
    allocator: std.mem.Allocator,
    keys: std.AutoArrayHashMap(Vec2, u8),
    arm: Vec2 = .{ 3, 2 },

    pub fn init(allocator: std.mem.Allocator) !NumPad {
        var keys = std.AutoArrayHashMap(Vec2, u8).init(allocator);
        try keys.put(.{ 3, 1 }, '0');
        try keys.put(.{ 3, 2 }, 'A');
        try keys.put(.{ 2, 0 }, '1');
        try keys.put(.{ 2, 1 }, '2');
        try keys.put(.{ 2, 2 }, '3');
        try keys.put(.{ 1, 0 }, '4');
        try keys.put(.{ 1, 1 }, '5');
        try keys.put(.{ 1, 2 }, '6');
        try keys.put(.{ 0, 0 }, '7');
        try keys.put(.{ 0, 1 }, '8');
        try keys.put(.{ 0, 2 }, '9');

        return NumPad{ .allocator = allocator, .keys = keys };
    }

    pub fn deinit(self: *NumPad) void {
        self.keys.deinit();
    }

    pub fn push(self: *NumPad, key: u8) ![]const u8 {
        const pos: Vec2 = switch (key) {
            '0' => .{ 3, 1 },
            '1' => .{ 2, 0 },
            '2' => .{ 2, 1 },
            '3' => .{ 2, 2 },
            '4' => .{ 1, 0 },
            '5' => .{ 1, 1 },
            '6' => .{ 1, 2 },
            '7' => .{ 0, 0 },
            '8' => .{ 0, 1 },
            '9' => .{ 0, 2 },
            'A' => .{ 3, 2 },
            else => return error.InvalidCharacter,
        };
        const path = try aStar(self.allocator, self.keys, self.arm, pos);
        defer self.allocator.free(path);
        self.arm = pos;

        const dirs = try dirsFromPath(self.allocator, path);
        defer self.allocator.free(dirs);

        return toString(self.allocator, dirs);
    }

    pub fn do(self: *NumPad, x: []const u8) ![]const u8 {
        var y = std.ArrayList(u8).init(self.allocator);
        defer y.deinit();
        for (x) |c| {
            if (c == '^') {
                self.arm += Vec2{ -1, 0 };
            } else if (c == 'v') {
                self.arm += Vec2{ 1, 0 };
            } else if (c == '<') {
                self.arm += Vec2{ 0, -1 };
            } else if (c == '>') {
                self.arm += Vec2{ 0, 1 };
            } else if (c == 'A') {
                try y.append(self.keys.get(self.arm).?);
            } else {
                return error.InvalidCharacter;
            }
        }

        return y.toOwnedSlice();
    }
};

const DirPad = struct {
    allocator: std.mem.Allocator,
    keys: std.AutoArrayHashMap(Vec2, u8),
    arm: Vec2 = .{ 0, 2 },

    pub fn init(allocator: std.mem.Allocator) !DirPad {
        var keys = std.AutoArrayHashMap(Vec2, u8).init(allocator);
        try keys.put(.{ 0, 1 }, '^');
        try keys.put(.{ 0, 2 }, 'A');
        try keys.put(.{ 1, 0 }, '<');
        try keys.put(.{ 1, 1 }, 'v');
        try keys.put(.{ 1, 2 }, '>');

        return DirPad{ .allocator = allocator, .keys = keys };
    }

    pub fn deinit(self: *DirPad) void {
        self.keys.deinit();
    }

    pub fn push(self: *DirPad, key: u8) ![]const u8 {
        const pos: Vec2 = switch (key) {
            '^' => .{ 0, 1 },
            'v' => .{ 1, 1 },
            '<' => .{ 1, 0 },
            '>' => .{ 1, 2 },
            'A' => .{ 0, 2 },
            else => return error.InvalidCharacter,
        };

        const path = try aStar(self.allocator, self.keys, self.arm, pos);
        // std.debug.print("path from aStar: {any}\n", .{path});
        defer self.allocator.free(path);
        self.arm = pos;

        const dirs = try dirsFromPath(self.allocator, path);
        defer self.allocator.free(dirs);

        return toString(self.allocator, dirs);
    }

    pub fn do(self: *DirPad, x: []const u8) ![]const u8 {
        var y = std.ArrayList(u8).init(self.allocator);
        defer y.deinit();
        for (x) |c| {
            if (c == '^') {
                self.arm += Vec2{ -1, 0 };
            } else if (c == 'v') {
                self.arm += Vec2{ 1, 0 };
            } else if (c == '<') {
                self.arm += Vec2{ 0, -1 };
            } else if (c == '>') {
                self.arm += Vec2{ 0, 1 };
            } else if (c == 'A') {
                try y.append(self.keys.get(self.arm).?);
            } else {
                return error.InvalidCharacter;
            }
        }

        return y.toOwnedSlice();
    }
};

pub fn dirsFromPath(allocator: std.mem.Allocator, path: []const Vec2) ![]Vec2 {
    var dirs = std.ArrayList(Vec2).init(allocator);
    defer dirs.deinit();

    for (path[1..], 0..) |pos, i| {
        const dir = pos - path[i];
        try dirs.append(dir);
    }

    return dirs.toOwnedSlice();
}
fn manhattanDistance(a: Vec2, b: Vec2) i64 {
    const x: i64 = @intCast(@abs(a[0] - b[0]));
    const y: i64 = @intCast(@abs(a[1] - b[1]));
    return x + y;
}

fn lessThan(context: void, a: PqItem, b: PqItem) std.math.Order {
    _ = context;
    return std.math.order(a.f_score, b.f_score);
}

const PqItem = struct {
    pos: Vec2,
    f_score: i64,
    direction: Vec2,
};

const directions = [_]Vec2{
    Vec2{ -1, 0 },
    Vec2{ 1, 0 },
    Vec2{ 0, -1 },
    Vec2{ 0, 1 },
};

pub fn aStar2(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2, goal: Vec2) ![]Vec2 {
    var open_set = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer open_set.deinit();
    try open_set.add(.{ .pos = start, .f_score = manhattanDistance(start, goal) });

    var came_from = std.AutoArrayHashMap(Vec2, Vec2).init(allocator);
    defer came_from.deinit();

    var g_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    while (open_set.count() != 0) {
        const current = open_set.remove();

        if (std.meta.eql(current.pos, goal)) {
            return reconstructPath(allocator, came_from, current.pos);
        }

        for (directions) |dir| {
            const neighbor = current.pos + dir;
            if (!maze.contains(neighbor)) {
                continue;
            }

            const tentative_g_score: i64 = g_score.get(current.pos).? + 1;

            if (tentative_g_score < (g_score.get(neighbor) orelse std.math.maxInt(i64))) {
                try came_from.put(neighbor, current.pos);
                try g_score.put(neighbor, tentative_g_score);
                try open_set.add(.{
                    .pos = neighbor,
                    .f_score = tentative_g_score + manhattanDistance(neighbor, goal),
                });
            }
        }
    }

    return error.PathNotFound;
}

pub fn aStar(allocator: std.mem.Allocator, maze: std.AutoArrayHashMap(Vec2, u8), start: Vec2, goal: Vec2) ![]Vec2 {
    var open_set = std.PriorityQueue(PqItem, void, lessThan).init(allocator, {});
    defer open_set.deinit();
    try open_set.add(.{ .pos = start, .f_score = manhattanDistance(start, goal), .direction = Vec2{ 0, 0 } });

    var came_from = std.AutoArrayHashMap(Vec2, Vec2).init(allocator);
    defer came_from.deinit();

    var g_score = std.AutoArrayHashMap(Vec2, i64).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    while (open_set.count() != 0) {
        const current = open_set.remove();

        if (std.meta.eql(current.pos, goal)) {
            return reconstructPath(allocator, came_from, current.pos);
        }

        for (directions) |dir| {
            const neighbor = current.pos + dir;
            if (!maze.contains(neighbor)) {
                continue;
            }

            const tentative_g_score: i64 = g_score.get(current.pos).? + 1;
            const direction_penalty: i64 = if (std.meta.eql(current.direction, Vec2{ 0, 0 }) or std.meta.eql(current.direction, dir)) 0 else 100;
            const tentative_f_score = tentative_g_score + manhattanDistance(neighbor, goal) + direction_penalty;

            if (tentative_g_score < (g_score.get(neighbor) orelse std.math.maxInt(i64))) {
                try came_from.put(neighbor, current.pos);
                try g_score.put(neighbor, tentative_g_score);
                try open_set.add(.{
                    .pos = neighbor,
                    .f_score = tentative_f_score,
                    .direction = dir,
                });
            }
        }
    }

    return error.PathNotFound;
}

fn reconstructPath(allocator: std.mem.Allocator, cameFrom: std.AutoArrayHashMap(Vec2, Vec2), current: Vec2) ![]Vec2 {
    var totalPath = std.ArrayList(Vec2).init(allocator);
    defer totalPath.deinit();

    try totalPath.append(current);
    var curr = current;
    while (cameFrom.contains(curr)) {
        curr = cameFrom.get(curr).?;
        try totalPath.append(curr);
    }

    const arr = try totalPath.toOwnedSlice();
    std.mem.reverse(Vec2, arr);

    return arr;
}
