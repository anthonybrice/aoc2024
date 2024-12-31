const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    machines: []ClawMachine,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.machines);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);

    var sections = std.mem.tokenizeSequence(u8, in, "\n\n");
    var machines = std.ArrayList(ClawMachine).init(allocator);
    defer machines.deinit();
    while (sections.next()) |section| {
        const machine = try ClawMachine.parse(section);
        try machines.append(machine);
    }

    ctx.allocator = allocator;
    ctx.machines = try machines.toOwnedSlice();

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var sum: u64 = 0;
    for (ctx.machines) |machine| {
        sum += machine.prizeMoves() catch continue;
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

const ClawMachine = struct {
    a: [2]u64,
    b: [2]u64,
    prize: [2]u64,

    pub fn parse(in: []const u8) !ClawMachine {
        var lines = std.mem.tokenizeScalar(u8, in, '\n');

        const button_a_line = lines.next().?;
        const a = try parseButton(button_a_line);

        const button_b_line = lines.next().?;
        const b = try parseButton(button_b_line);

        const prize_line = lines.next().?;
        const prize = try parsePrize(prize_line);

        return ClawMachine{ .a = a, .b = b, .prize = prize };
    }

    fn parseButton(in: []const u8) ![2]u64 {
        var tokens = std.mem.tokenizeAny(u8, in, ",+");
        _ = tokens.next();
        const x = try std.fmt.parseInt(u64, tokens.next().?, 10);
        _ = tokens.next();
        const y = try std.fmt.parseInt(u64, tokens.next().?, 10);
        return .{ x, y };
    }

    fn parsePrize(in: []const u8) ![2]u64 {
        var tokens = std.mem.tokenizeAny(u8, in, "=,");
        _ = tokens.next();
        const x = try std.fmt.parseInt(u64, tokens.next().?, 10);
        _ = tokens.next();
        const y = try std.fmt.parseInt(u64, tokens.next().?, 10);

        return .{ x, y };
    }

    pub fn prizeMoves(self: ClawMachine) !u64 {
        const x1: f64 = @floatFromInt(self.a[0]);
        const x2: f64 = @floatFromInt(self.a[1]);
        const y1: f64 = @floatFromInt(self.b[0]);
        const y2: f64 = @floatFromInt(self.b[1]);
        const z1: f64 = @floatFromInt(self.prize[0]);
        const z2: f64 = @floatFromInt(self.prize[1]);

        const m = (x1 * z2 - x2 * z1) / (x1 * y2 - x2 * y1);
        const n = (z1 - m * y1) / x1;

        if (m < 0 or n < 0) {
            return error.NoCombination;
        }

        if (std.math.ceil(m) != m or std.math.ceil(n) != n) {
            return error.NoCombination;
        }

        const int_m: u64 = @intFromFloat(m);
        const int_n: u64 = @intFromFloat(n);

        return 3 * int_n + int_m;
    }
};
