const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_contents = try util.readFile(allocator, path);
    defer allocator.free(file_contents);

    var lines = std.mem.tokenizeSequence(u8, file_contents, "\n");

    var sum: u64 = 0;
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeAny(u8, line, ": ");
        const solution = try std.fmt.parseInt(u64, tokens.next().?, 10);
        var operands_list = std.ArrayList(u64).init(allocator);
        // defer operands.deinit();
        while (tokens.next()) |token| {
            const operand = try std.fmt.parseInt(u64, token, 10);
            try operands_list.append(operand);
        }
        const operands = try operands_list.toOwnedSlice();
        defer allocator.free(operands);

        if (checkCombinations(operands, solution)) {
            // std.debug.print("Solution found for line: {any}: {any}\n", .{ solution, operands });
            sum += solution;
        }
    }
    std.debug.print("{d}\n", .{sum});
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
