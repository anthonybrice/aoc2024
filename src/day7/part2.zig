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
        while (tokens.next()) |token| {
            const operand = try std.fmt.parseInt(u64, token, 10);
            try operands_list.append(operand);
        }
        const operands = try operands_list.toOwnedSlice();
        defer allocator.free(operands);

        if (try checkCombinations(operands, solution)) {
            sum += solution;
        }
    }
    std.debug.print("{d}\n", .{sum});
}

fn checkCombinations(operands: []const u64, solution: u64) !bool {
    const num_operands = operands.len;
    const num_combinations = std.math.pow(u64, 3, num_operands - 1);

    for (0..num_combinations) |combination| {
        var result = operands[0];
        var combination_copy = combination;

        for (1..num_operands) |i| {
            const operand = operands[i];
            const operator = combination_copy % 3;
            combination_copy /= 3;

            if (operator == 0) {
                result += operand;
            } else if (operator == 1) {
                result *= operand;
            } else if (operator == 2) {
                result = try concatenateInts(result, operand);
            }
        }

        if (result == solution) {
            return true;
        }
    }

    return false;
}

fn concatenateInts(a: u64, b: u64) !u64 {
    var buffer: [100]u8 = undefined;
    const num_string = try std.fmt.bufPrint(&buffer, "{d}{d}", .{ a, b });
    return try std.fmt.parseInt(u64, num_string, 10);
}
