const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");
    var robots = std.ArrayList(Robot).init(allocator);
    defer robots.deinit();
    while (lines.next()) |line| {
        try robots.append(try Robot.parseRobot(line));
    }

    for (0..100) |_| {
        for (robots.items) |*robot| {
            robot.move();
        }
    }

    const width = grid[0];
    const height = grid[1];
    const mid_x = width / 2;
    const mid_y = height / 2;

    var quads = [4]usize{ 0, 0, 0, 0 };

    for (robots.items) |robot| {
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

    std.debug.print("{d}\n", .{quads[0] * quads[1] * quads[2] * quads[3]});
}

const grid = [2]i64{ 101, 103 };

const Robot = struct {
    pos: @Vector(2, i64),
    v: @Vector(2, i64),

    fn parseRobot(line: []const u8) !Robot {
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

    fn move(self: *Robot) void {
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
