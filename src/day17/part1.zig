const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i64);

pub const Context = struct {
    allocator: Allocator,
    computer: Computer,

    pub fn deinit(self: *Context) void {
        self.computer.deinit();
    }
};

pub fn parse(allocator: Allocator, in: []const u8) !*Context {
    var ctx = try allocator.create(Context);
    ctx.allocator = allocator;
    ctx.computer = try Computer.init(allocator, in);

    return ctx;
}

pub fn part1(ctx: *Context) ![]const u8 {
    var comp = try ctx.computer.clone();
    defer comp.deinit();
    try comp.run();

    var out = std.ArrayList(u8).init(ctx.allocator);
    defer out.deinit();
    for (comp.out.items) |x| {
        var buf: [2]u8 = undefined;
        const str = try std.fmt.bufPrint(&buf, "{d},", .{x});
        try out.appendSlice(str);
    }

    const foo = std.mem.trimRight(u8, out.items, ",");
    const bar = try ctx.allocator.alloc(u8, foo.len);
    @memcpy(bar, foo);

    return bar;
}

const Computer = struct {
    allocator: std.mem.Allocator,
    register_a: i64,
    register_b: i64,
    register_c: i64,

    instructions: []i64,
    instr_ptr: i64 = 0,

    out: std.ArrayList(i64),

    fn clone(self: Computer) !Computer {
        const instructions = try self.allocator.alloc(i64, self.instructions.len);
        @memcpy(instructions, self.instructions);

        return Computer{
            .allocator = self.allocator,
            .register_a = self.register_a,
            .register_b = self.register_b,
            .register_c = self.register_c,
            .instructions = instructions,
            .instr_ptr = self.instr_ptr,
            .out = try self.out.clone(),
        };
    }

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

    pub fn init(allocator: std.mem.Allocator, line: []const u8) !Computer {
        var lines = std.mem.tokenizeSequence(u8, line, "\n");

        const register_a = try parseRegister(lines.next().?);
        const register_b = try parseRegister(lines.next().?);
        const register_c = try parseRegister(lines.next().?);

        const instructions = try parseInstructions(allocator, lines.next().?);

        return Computer{
            .allocator = allocator,
            .register_a = register_a,
            .register_b = register_b,
            .register_c = register_c,
            .instructions = instructions,
            .out = std.ArrayList(i64).init(allocator),
        };
    }

    pub fn deinit(self: Computer) void {
        self.allocator.free(self.instructions);
        self.out.deinit();
    }

    pub fn step(self: *Computer) !void {
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

    pub fn run(self: *Computer) !void {
        while (self.instr_ptr < self.instructions.len) {
            try self.step();
        }
    }

    pub fn runOnce(self: *Computer) !void {
        while (self.instr_ptr < self.instructions.len) {
            if (self.instr_ptr == 0 and self.out.items.len > 0) break;
            try self.step();
        }
    }

    fn getComboOp(self: *Computer) i64 {
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

    fn print(self: Computer) void {
        std.debug.print("Register A: {d}\n", .{self.register_a});
        std.debug.print("Register B: {d}\n", .{self.register_b});
        std.debug.print("Register C: {d}\n", .{self.register_c});
        std.debug.print("Program: ", .{});
        for (self.instructions) |instr| {
            std.debug.print("{d},", .{instr});
        }
        std.debug.print("\n", .{});
        std.debug.print("instr_ptr: {d}\n", .{self.instr_ptr});
        std.debug.print("Output: {any}\n", .{self.out.items});
    }

    fn reset(self: *Computer, a: i64) void {
        self.register_a = a;
        self.register_b = 0;
        self.register_c = 0;
        self.instr_ptr = 0;
        self.out.clearRetainingCapacity();
    }

    pub fn findA(self: *Computer) !i64 {
        return try self.solve(0, 0);
    }

    pub fn solve(self: *Computer, i: i64, offset: usize) !i64 {
        const len = self.instructions.len;
        if (offset == len) {
            return i;
        }

        for (0..8) |j| {
            if (i == 0 and j == 0) continue;
            const a_val: i64 = i * 8 + @as(i64, @intCast(j));
            self.reset(a_val);
            try self.runOnce();
            if (self.register_a != i) continue;
            if (self.out.items.len < 1) continue;
            if (self.instructions[len - offset - 1] == self.out.items[0]) {
                const v = try self.solve(a_val, offset + 1);
                if (v > 0) return v;
            }
        }

        return 0;
    }
};
