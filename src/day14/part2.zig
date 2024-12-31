const std = @import("std");
const Allocator = std.mem.Allocator;
const Context = @import("part1.zig").Context;
const Robot = @import("part1.zig").Robot;

pub fn part2(ctx: *Context) ![]const u8 {
    const robots_ = try ctx.allocator.alloc(Robot, ctx.robots.len);
    defer ctx.allocator.free(robots_);
    @memcpy(robots_, ctx.robots);

    var seconds: u64 = 0;
    while (true) {
        for (robots_) |*robot| {
            robot.move();
        }
        seconds += 1;
        if (try checkXmasTree(robots_)) {
            break;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{seconds});
}

fn checkXmasTree(robots: []Robot) !bool {
    var map: [101][103]u8 = .{.{'.'} ** 103} ** 101;
    for (robots) |r| {
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
