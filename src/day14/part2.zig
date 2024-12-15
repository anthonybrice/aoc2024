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

    var seconds: u64 = 0;
    while (true) {
        for (robots.items) |*robot| {
            robot.move();
        }
        seconds += 1;
        if (try checkXmasTree(robots)) {
            break;
        }
    }

    std.debug.print("{d}\n", .{seconds});
}

fn checkXmasTree(robots: std.ArrayList(Robot)) !bool {
    var map: [101][103]u8 = .{.{'.'} ** 103} ** 101;
    for (robots.items) |r| {
        const u_pos_x: usize = @intCast(r.pos[0]);
        const u_pos_y: usize = @intCast(r.pos[1]);
        if (map[u_pos_x][u_pos_y] != '.') {
            return false;
        } else {
            map[u_pos_x][u_pos_y] = '1';
        }
    }

    return true;
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
