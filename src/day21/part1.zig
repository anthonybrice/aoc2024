const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../main.zig");
const pf = @import("pathfind.zig");

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    in: []const u8,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.in);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    const new_in = try allocator.alloc(u8, in.len);
    @memcpy(new_in, in);
    ctx.in = new_in;

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const allocator = ctx.allocator;
    var lines = std.mem.tokenizeScalar(u8, ctx.in, '\n');

    var sum: usize = 0;
    while (lines.next()) |line| {
        const seq = try shortestSequence(
            allocator,
            line,
        );
        defer allocator.free(seq);

        const num: usize = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);
        sum += (seq.len) * num;
    }

    return std.fmt.allocPrint(allocator, "{d}", .{sum});
}

fn shortestSequence(
    allocator: std.mem.Allocator,
    code: []const u8,
) ![]const u8 {
    var num_pad = try Pad.numPad(allocator);
    defer num_pad.deinit();
    var dir_pad1 = try Pad.dirPad(allocator);
    defer dir_pad1.deinit();
    var dir_pad2 = try Pad.dirPad(allocator);
    defer dir_pad2.deinit();

    var sequence = std.ArrayList(u8).init(allocator);
    defer sequence.deinit();
    for (code) |c| {
        const np_path = try num_pad.push(c);
        defer allocator.free(np_path);

        var d1_path = std.ArrayList(u8).init(allocator);
        defer d1_path.deinit();
        for (np_path) |k| {
            const dir1_instrs = try dir_pad1.push(k);
            defer allocator.free(dir1_instrs);
            try d1_path.appendSlice(dir1_instrs);
        }

        var d2_path = std.ArrayList(u8).init(allocator);
        defer d2_path.deinit();
        for (d1_path.items) |k| {
            const dir2_instrs = try dir_pad2.push(k);
            defer allocator.free(dir2_instrs);
            try d2_path.appendSlice(dir2_instrs);
        }
        try sequence.appendSlice(d2_path.items);
    }

    return sequence.toOwnedSlice();
}

pub fn toString(allocator: std.mem.Allocator, instrs: []const Vec2) ![]const u8 {
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
            return error.InvalidInstruction;
        }
    }
    try str.append('A');

    return str.toOwnedSlice();
}

pub const Pad = struct {
    allocator: std.mem.Allocator,
    pad_map: std.AutoArrayHashMap(Vec2, u8),
    inverse_map: std.AutoArrayHashMap(u8, Vec2),
    path_map: std.AutoArrayHashMap([2]Vec2, []Vec2),
    arm: Vec2,

    pub fn init(allocator: std.mem.Allocator, pad_map: std.AutoArrayHashMap(Vec2, u8)) !Pad {
        var inverse_map = std.AutoArrayHashMap(u8, Vec2).init(allocator);
        var path_map = std.AutoArrayHashMap([2]Vec2, []Vec2).init(allocator);
        for (pad_map.keys()) |k| {
            const v = pad_map.get(k).?;
            try inverse_map.put(v, k);

            var ps = try pf.shortestPaths(allocator, pad_map, k);
            defer ps.deinit();
            for (ps.keys()) |end| {
                const path = ps.get(end).?;
                try path_map.put(.{ k, end }, path);
            }
        }

        return Pad{
            .allocator = allocator,
            .pad_map = pad_map,
            .inverse_map = inverse_map,
            .path_map = path_map,
            .arm = inverse_map.get('A').?,
        };
    }

    pub fn deinit(self: *Pad) void {
        self.pad_map.deinit();
        self.inverse_map.deinit();
        for (self.path_map.values()) |v| {
            self.allocator.free(v);
        }
        self.path_map.deinit();
    }

    pub fn push(self: *Pad, key: u8) ![]const u8 {
        const pos = self.inverse_map.get(key).?;

        const path = self.path_map.get(.{ self.arm, pos }).?;
        self.arm = pos;

        const dirs = try dirsFromPath(self.allocator, path);
        defer self.allocator.free(dirs);

        return toString(self.allocator, dirs);
    }

    pub fn do(self: *Pad, x: []const u8) ![]const u8 {
        var y = std.ArrayList(u8).init(self.allocator);
        defer y.deinit();
        for (x) |c| {
            switch (c) {
                '^' => self.arm += Vec2{ -1, 0 },
                'v' => self.arm += Vec2{ 1, 0 },
                '<' => self.arm += Vec2{ 0, -1 },
                '>' => self.arm += Vec2{ 0, 1 },
                'A' => try y.append(self.pad_map.get(self.arm).?),
                _ => return error.InvalidCharacter,
            }
        }

        return y.toOwnedSlice();
    }

    pub fn numPad(allocator: std.mem.Allocator) !Pad {
        var pad_map = std.AutoArrayHashMap(Vec2, u8).init(allocator);

        try pad_map.put(.{ 0, 0 }, '7');
        try pad_map.put(.{ 0, 1 }, '8');
        try pad_map.put(.{ 0, 2 }, '9');
        try pad_map.put(.{ 1, 0 }, '4');
        try pad_map.put(.{ 1, 1 }, '5');
        try pad_map.put(.{ 1, 2 }, '6');
        try pad_map.put(.{ 2, 0 }, '1');
        try pad_map.put(.{ 2, 1 }, '2');
        try pad_map.put(.{ 2, 2 }, '3');
        try pad_map.put(.{ 3, 1 }, '0');
        try pad_map.put(.{ 3, 2 }, 'A');

        return Pad.init(allocator, pad_map);
    }

    pub fn dirPad(allocator: std.mem.Allocator) !Pad {
        var pad_map = std.AutoArrayHashMap(Vec2, u8).init(allocator);

        try pad_map.put(.{ 0, 1 }, '^');
        try pad_map.put(.{ 0, 2 }, 'A');
        try pad_map.put(.{ 1, 0 }, '<');
        try pad_map.put(.{ 1, 1 }, 'v');
        try pad_map.put(.{ 1, 2 }, '>');

        return Pad.init(allocator, pad_map);
    }

    fn dirsFromPath(allocator: std.mem.Allocator, path: []const Vec2) ![]Vec2 {
        var dirs = std.ArrayList(Vec2).init(allocator);
        defer dirs.deinit();

        for (path[1..], 0..) |pos, i| {
            const dir = pos - path[i];
            try dirs.append(dir);
        }

        return dirs.toOwnedSlice();
    }
};
