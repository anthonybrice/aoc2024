const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../main.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    input: []const u8,

    pub fn deinit(self: *Context) void {
        self.allocator.free(self.input);
    }
};

pub fn parse(allocator: Allocator, input: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.input = try std.fmt.allocPrint(allocator, "{s}", .{input});

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var lines = std.mem.tokenizeSequence(u8, ctx.input, "\n");

    var sum: u64 = 0;
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeAny(u8, line, ": ");
        const solution = try std.fmt.parseInt(u64, tokens.next().?, 10);
        var operands_list = std.ArrayList(u64).init(ctx.allocator);
        defer operands_list.deinit();
        while (tokens.next()) |token| {
            const operand = try std.fmt.parseInt(u64, token, 10);
            try operands_list.append(operand);
        }
        const operands = try operands_list.toOwnedSlice();
        defer ctx.allocator.free(operands);

        if (checkCombinations(operands, solution)) {
            sum += solution;
        }
    }

    return try std.fmt.allocPrint(ctx.allocator, "{d}", .{sum});
}

fn checkCombinations(operands: []const u64, solution: u64) bool {
    const num_operands: u64 = operands.len;
    const num_combinations = std.math.pow(u64, 2, num_operands - 1);

    for (0..num_combinations) |combination| {
        var result = operands[0];
        var combination_copy = combination;

        for (1..num_operands) |i| {
            const operand = operands[i];
            if ((combination_copy & 1) == 0) {
                result += operand;
            } else {
                result *= operand;
            }
            combination_copy >>= 1;
        }

        if (result == solution) {
            return true;
        }
    }

    return false;
}
