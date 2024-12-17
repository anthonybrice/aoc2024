const std = @import("std");
const util = @import("../main.zig");

const Vec2 = @Vector(2, i64);

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var comp = try Comp.init(allocator, file_contents);
    defer comp.deinit();

    try comp.run();
    for (comp.out.items) |item| {
        std.debug.print("{d},", .{item});
    }
    std.debug.print("\n", .{});
    comp.print();
}

const Comp = struct {
    allocator: std.mem.Allocator,
    register_a: i64,
    register_b: i64,
    register_c: i64,

    instructions: []i64,
    instr_ptr: i64 = 0,

    out: std.ArrayList(i64),

    fn parseRegister(line: []const u8) !i64 {
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        _ = tokens.next();
        _ = tokens.next();
        return std.fmt.parseInt(i64, tokens.next().?, 10);
    }

    fn parseInstructions(allocator: std.mem.Allocator, line: []const u8) ![]i64 {
        var tokens = std.mem.tokenizeAny(u8, line, " ,");
        _ = tokens.next();
        var instr_list = std.ArrayList(i64).init(allocator);

        while (tokens.next()) |token| {
            const instr = try std.fmt.parseInt(i64, token, 10);
            try instr_list.append(instr);
        }

        return instr_list.toOwnedSlice();
    }

    fn init(allocator: std.mem.Allocator, line: []const u8) !Comp {
        var lines = std.mem.tokenizeSequence(u8, line, "\n");

        const register_a = try parseRegister(lines.next().?);
        const register_b = try parseRegister(lines.next().?);
        const register_c = try parseRegister(lines.next().?);
        const instructions = try parseInstructions(allocator, lines.next().?);

        return Comp{
            .allocator = allocator,
            .register_a = register_a,
            .register_b = register_b,
            .register_c = register_c,
            .instructions = instructions,
            .out = std.ArrayList(i64).init(allocator),
        };
    }

    fn deinit(self: Comp) void {
        self.allocator.free(self.instructions);
        self.out.deinit();
    }

    fn run(self: *Comp) !void {
        while (self.instr_ptr < self.instructions.len) {
            const ptr_u: usize = @intCast(self.instr_ptr);
            const opcode = self.instructions[ptr_u];
            switch (opcode) {
                0 => { // adv
                    const x = self.register_a;
                    const y = std.math.pow(i64, 2, self.getComboOp());
                    self.register_a = @divTrunc(x, y);
                    self.instr_ptr += 2;
                },
                1 => { // bxl
                    const x = self.register_b;
                    const y = self.instructions[ptr_u + 1];
                    self.register_b = x ^ y;
                    self.instr_ptr += 2;
                },
                2 => { // bst
                    const x = self.getComboOp();
                    self.register_b = @mod(x, 8);
                    self.instr_ptr += 2;
                },
                3 => { // jnz
                    if (self.register_a != 0) {
                        self.instr_ptr = self.instructions[ptr_u + 1];
                    } else {
                        self.instr_ptr += 2;
                    }
                },
                4 => { // bxc
                    self.register_b ^= self.register_c;
                    self.instr_ptr += 2;
                },
                5 => { // out
                    const x = @mod(self.getComboOp(), 8);
                    try self.out.append(x);
                    self.instr_ptr += 2;
                },
                6 => { //bdv
                    const x = self.register_a;
                    const y = std.math.pow(i64, 2, self.getComboOp());
                    self.register_b = @divTrunc(x, y);
                    self.instr_ptr += 2;
                },
                7 => { // cdv
                    const x = self.register_a;
                    const y = std.math.pow(i64, 2, self.getComboOp());
                    self.register_c = @divTrunc(x, y);
                    self.instr_ptr += 2;
                },
                else => {
                    return error.UnknownOpcode;
                },
            }
        }
    }

    fn getComboOp(self: *Comp) i64 {
        const ptr_u: usize = @intCast(self.instr_ptr);
        const operand = self.instructions[ptr_u + 1];
        switch (operand) {
            0, 1, 2, 3 => return operand,
            4 => return self.register_a,
            5 => return self.register_b,
            6 => return self.register_c,
            else => return 0,
        }
    }

    fn print(self: Comp) void {
        std.debug.print("Register A: {d}\n", .{self.register_a});
        std.debug.print("Register B: {d}\n", .{self.register_b});
        std.debug.print("Register C: {d}\n", .{self.register_c});
        std.debug.print("\nProgram: ", .{});
        for (self.instructions) |instr| {
            std.debug.print("{d},", .{instr});
        }
        std.debug.print("\n", .{});
    }
};
