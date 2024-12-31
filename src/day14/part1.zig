const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Context = struct {
    allocator: Allocator,
    robots: []Robot,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.robots);
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);

    var lines = std.mem.tokenizeSequence(u8, in, "\n");
    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();
    while (lines.next()) |line| {
        try robots.append(try Robot.parseRobot(line));
    }

    ctx.allocator = allocator;
    ctx.robots = try robots.toOwnedSlice();

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    const width = grid[0];
    const height = grid[1];
    const mid_x = width / 2;
    const mid_y = height / 2;

    const robots_ = try ctx.allocator.alloc(Robot, ctx.robots.len);
    defer ctx.allocator.free(robots_);
    @memcpy(robots_, ctx.robots);

    for (0..100) |_| {
        for (robots_) |*robot| {
            robot.move();
        }
    }

    var quads = [4]usize{ 0, 0, 0, 0 };

    for (robots_) |robot| {
        const pos = robot.pos;
        if (pos[0] == mid_x or pos[1] == mid_y) {
            continue;
        } else if (pos[0] < mid_x and pos[1] < mid_y) {
            quads[0] += 1;
        } else if (pos[0] > mid_x and pos[1] < mid_y) {
            quads[1] += 1;
        } else if (pos[0] < mid_x and pos[1] > mid_y) {
            quads[2] += 1;
        } else if (pos[0] > mid_x and pos[1] > mid_y) {
            quads[3] += 1;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{quads[0] * quads[1] * quads[2] * quads[3]});
}

const grid = [2]i64{ 101, 103 };

pub const Robot = struct {
    pos: @Vector(2, i64),
    v: @Vector(2, i64),

    pub fn parseRobot(line: []const u8) !Robot {
        var tokens = std.mem.tokenizeAny(u8, line, "p=,v ");

        const px = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const py = try std.fmt.parseInt(i64, tokens.next().?, 10);

        const vx = try std.fmt.parseInt(i64, tokens.next().?, 10);
        const vy = try std.fmt.parseInt(i64, tokens.next().?, 10);

        return Robot{
            .pos = .{ px, py },
            .v = .{ vx, vy },
        };
    }

    pub fn move(self: *Robot) void {
        self.pos = self.pos + self.v;
        if (self.pos[0] < 0) {
            self.pos[0] = self.pos[0] + grid[0];
        } else if (self.pos[0] >= grid[0]) {
            self.pos[0] = self.pos[0] - grid[0];
        }

        if (self.pos[1] < 0) {
            self.pos[1] = self.pos[1] + grid[1];
        } else if (self.pos[1] >= grid[1]) {
            self.pos[1] = self.pos[1] - grid[1];
        }
    }
};
