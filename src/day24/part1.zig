const std = @import("std");
const util = @import("../main.zig");

pub fn main(allocator: std.mem.Allocator, filepath: []const u8) !void {
    const file_contents = try util.readFile(allocator, filepath);
    defer allocator.free(file_contents);

    var device = try Device.init(allocator, file_contents);
    defer device.deinit();
    try device.eval();
    const z_value = try device.getValue('z');
    std.debug.print("{d}\n", .{z_value});
}

const GateOp = enum {
    AND,
    OR,
    XOR,
};

const Gate = struct {
    in1: []const u8,
    in2: []const u8,
    out: []const u8,
    op: GateOp,

    fn eql(self: Gate, other: Gate) bool {
        return std.mem.eql(u8, self.in1, other.in1) and
            std.mem.eql(u8, self.in2, other.in2) and
            std.mem.eql(u8, self.out, other.out) and
            self.op == other.op;
    }

    pub fn format(
        self: Gate,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s} {s} {s} -> {s}", .{
            self.in1,
            @tagName(self.op),
            self.in2,
            self.out,
        });
    }

    const HashContext = struct {
        pub fn hash(_: HashContext, key: Gate) u32 {
            var h = std.hash.Wyhash.init(0);
            h.update(key.in1);
            h.update(key.in2);
            h.update(key.out);
            h.update(@tagName(key.op));

            return @truncate(h.final());
        }

        pub fn eql(_: HashContext, a: Gate, b: Gate, _: usize) bool {
            return a.eql(b);
        }
    };
};

pub const Device = struct {
    allocator: std.mem.Allocator,
    wires: std.StringArrayHashMap(?u8),
    gates: []Gate,

    pub fn init(allocator: std.mem.Allocator, in: []const u8) !Device {
        var sections = std.mem.tokenizeSequence(u8, in, "\n\n");
        var wires = try parseInputWires(allocator, sections.next().?);

        var gates = std.ArrayList(Gate).init(allocator);
        defer gates.deinit();
        var gate_lines = std.mem.tokenizeScalar(u8, sections.next().?, '\n');
        while (gate_lines.next()) |line| {
            const gate = try parseGate(&wires, line);
            try gates.append(gate);
        }

        return .{
            .allocator = allocator,
            .wires = wires,
            .gates = try gates.toOwnedSlice(),
        };
    }

    pub fn deinit(self: *Device) void {
        self.wires.deinit();
        self.allocator.free(self.gates);
    }

    fn evalWithCount(self: *Device, count: u64) !void {
        for (self.gates) |*gate| {
            if (self.wires.get(gate.in1).? == null or
                self.wires.get(gate.in2).? == null)
            {
                continue;
            }

            const v1 = self.wires.get(gate.in1).?.?;
            const v2 = self.wires.get(gate.in2).?.?;

            var result: u8 = undefined;
            switch (gate.op) {
                .AND => {
                    if (v1 == 1 and v2 == 1) {
                        result = 1;
                    } else {
                        result = 0;
                    }
                },
                .OR => {
                    if (v1 == 1 or v2 == 1) {
                        result = 1;
                    } else {
                        result = 0;
                    }
                },
                .XOR => {
                    if (v1 != v2) {
                        result = 1;
                    } else {
                        result = 0;
                    }
                },
            }
            try self.wires.put(gate.out, result);
        }
        if (!self.allZsHaveValue() and count <= self.gates.len) {
            try self.evalWithCount(count + 1);
        } else if (!self.allZsHaveValue() and count > self.gates.len) {
            return error.Unevaluable;
        }
    }

    pub fn eval(self: *Device) !void {
        return self.evalWithCount(0);
    }

    fn parseGate(
        wires: *std.StringArrayHashMap(?u8),
        line: []const u8,
    ) !Gate {
        var tokens = std.mem.tokenizeAny(u8, line, " ->");
        var in1 = tokens.next().?;
        const op = tokens.next().?;
        var in2 = tokens.next().?;
        const out = tokens.next().?;

        if (!wires.contains(in1)) try wires.put(in1, null);
        if (!wires.contains(in2)) try wires.put(in2, null);
        if (!wires.contains(out)) try wires.put(out, null);

        const ch1 = in1[0];
        const ch2 = in2[0];
        if ((ch1 == 'y' and ch2 == 'x') or
            (ch2 == 'y' and ch1 != 'x') or
            (ch2 == 'x' and ch1 != 'y') or
            (compareStrings({}, in1, in2) and ch1 != 'x' and ch1 != 'y' and ch2 != 'x' and ch2 != 'y'))
        {
            const x = in1;
            in1 = in2;
            in2 = x;
        }

        return .{
            .in1 = in1,
            .in2 = in2,
            .out = out,
            .op = std.meta.stringToEnum(GateOp, op).?,
        };
    }

    fn parseInputWires(allocator: std.mem.Allocator, section: []const u8) !std.StringArrayHashMap(?u8) {
        var lines = std.mem.tokenizeScalar(u8, section, '\n');
        var wires = std.StringArrayHashMap(?u8).init(allocator);

        while (lines.next()) |line| {
            var tokens = std.mem.tokenizeSequence(u8, line, ": ");
            const name = tokens.next().?;
            const value = tokens.next().?;
            try wires.put(name, value[0] - '0');
        }

        return wires;
    }

    fn allZsHaveValue(self: Device) bool {
        for (self.wires.keys()) |key| {
            if (key[0] == 'z' and self.wires.get(key).? == null) {
                return false;
            }
        }
        return true;
    }

    pub fn getValue(self: *Device, c: u8) !u64 {
        var z_list = std.StringArrayHashMap(u8).init(self.allocator);
        defer z_list.deinit();

        for (self.wires.keys()) |key| {
            if (key[0] == c) {
                try z_list.put(key, self.wires.get(key).?.?);
            }
        }

        var z_value = std.ArrayList(u8).init(self.allocator);
        defer z_value.deinit();
        for (0..z_list.count()) |i| {
            var z_num: []u8 = undefined;
            if (i < 10) {
                z_num = try std.fmt.allocPrint(self.allocator, "0{d}", .{i});
            } else {
                z_num = try std.fmt.allocPrint(self.allocator, "{d}", .{i});
            }
            defer self.allocator.free(z_num);
            const z_key = [_]u8{ c, z_num[0], z_num[1] };

            try z_value.append(z_list.get(&z_key).? + '0');
        }

        const z_string: []u8 = try z_value.toOwnedSlice();
        defer self.allocator.free(z_string);
        std.mem.reverse(u8, z_string);

        return try std.fmt.parseInt(u64, z_string, 2);
    }

    pub fn swap(self: *Device, a: []const u8, b: []const u8) !void {
        for (self.gates) |*gate| {
            if (std.mem.eql(u8, gate.out, a)) {
                gate.out = b;
            } else if (std.mem.eql(u8, gate.out, b)) {
                gate.out = a;
            }
        }
    }

    pub fn clone(self: Device) !Device {
        const wires = try self.wires.clone();
        const gates = try self.allocator.alloc(Gate, self.gates.len);
        @memcpy(gates, self.gates);

        return .{
            .allocator = self.allocator,
            .wires = wires,
            .gates = gates,
        };
    }

    const LogicGateGroup = std.ArrayHashMap(
        Gate,
        void,
        Gate.HashContext,
        true,
    );

    pub fn findSwitchedOutputs(self: Device) ![][2][]const u8 {
        var wrong_outputs = std.ArrayList([2][]const u8).init(self.allocator);
        defer wrong_outputs.deinit();

        // count the number of x/y/z bits
        var x_bits: u64 = 0;
        for (self.wires.keys()) |key| {
            if (key[0] == 'x') x_bits += 1;
        }

        var prev_output_name_carry_out: []const u8 = undefined;
        var output_name_carry_out: []const u8 = undefined;

        for (0..x_bits) |gate_index| {
            var group = std.ArrayList(Gate).init(self.allocator);
            defer group.deinit();

            for (self.gates) |gate| {
                const n_str = try twoDigitNumberString(gate_index);
                const x_key = [_]u8{ 'x', n_str[0], n_str[1] };
                const y_key = [_]u8{ 'y', n_str[0], n_str[1] };
                if (keyInGate(&x_key, gate) or keyInGate(&y_key, gate)) {
                    try group.append(gate);
                    if (gate_index > 0) {
                        for (self.gates) |gate2| {
                            if (keyInGate(gate.out, gate2) and !gate.eql(gate2)) {
                                var gate2_new = gate2;
                                if (std.mem.eql(u8, gate2_new.in2, gate.out)) {
                                    gate2_new = Gate{
                                        .in1 = gate2_new.in2,
                                        .op = gate2_new.op,
                                        .in2 = gate2_new.in1,
                                        .out = gate2_new.out,
                                    };
                                }
                                if (contains(group, gate2)) {
                                    _ = try remove(&group, gate2);
                                }
                                if (!contains(group, gate2_new)) {
                                    try group.append(gate2_new);
                                }

                                for (self.gates) |gate3| {
                                    if ((std.mem.eql(u8, gate2.out, gate3.in1) or
                                        std.mem.eql(u8, gate2.out, gate3.in2)) and
                                        gate2.op == GateOp.AND)
                                    {
                                        if (!contains(group, gate3) and !gate2.eql(gate3) and !gate3.eql(gate2_new) and !gate.eql(gate3)) {
                                            const gate3_new = Gate{
                                                .in1 = gate3.in2,
                                                .op = gate3.op,
                                                .in2 = gate3.in1,
                                                .out = gate3.out,
                                            };
                                            if (!contains(group, gate3_new)) {
                                                try group.append(gate3);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            try extractSwap(&group, "x", GateOp.XOR, 0, 0);
            try extractSwap(&group, "x", GateOp.AND, 0, 1);
            if (gate_index > 0) {
                try extractSwap(&group, "", GateOp.AND, 2, 2);
                try extractSwap(&group, "", GateOp.OR, 2, 3);
                try extractSwap(&group, "", GateOp.XOR, 2, 4);
            }

            var correct_outputs = std.ArrayList([]const u8).init(self.allocator);
            defer correct_outputs.deinit();
            if (gate_index == 0) {
                try correct_outputs.append("z00");
                try correct_outputs.append(group.items[1].out);
                prev_output_name_carry_out = group.items[0].out;
            } else {
                var outputs_1_to_3 = std.ArrayList([]const u8).init(self.allocator);
                defer outputs_1_to_3.deinit();
                try outputs_1_to_3.append(group.items[1].out);
                try outputs_1_to_3.append(group.items[2].out);
                try outputs_1_to_3.append(group.items[3].out);
                for (outputs_1_to_3.items, 0..) |test_out, i| {
                    var wrong = false;
                    for (group.items) |gate| {
                        if (std.mem.eql(u8, gate.in1, test_out) or
                            std.mem.eql(u8, gate.in2, test_out))
                        {
                            wrong = true;
                            break;
                        }
                    }
                    if (!wrong) {
                        output_name_carry_out = test_out;
                        _ = outputs_1_to_3.orderedRemove(i);
                        break;
                    }
                }

                var x: []const u8 = undefined;
                if (std.mem.eql(u8, group.items[2].in1, prev_output_name_carry_out)) {
                    x = group.items[2].in2;
                } else {
                    x = group.items[2].in1;
                }
                try correct_outputs.append(x);
                try correct_outputs.append(outputs_1_to_3.items[0]);
                try correct_outputs.append(outputs_1_to_3.items[1]);
                try correct_outputs.append(output_name_carry_out);
                const z_num = try twoDigitNumberString(gate_index);
                const entry = self.wires.getEntry(&[_]u8{ 'z', z_num[0], z_num[1] }).?;
                try correct_outputs.append(entry.key_ptr.*);
            }

            var diff = std.ArrayList([2][]const u8).init(self.allocator);
            defer diff.deinit();
            if (gate_index == 0) {
                if (!std.mem.eql(u8, group.items[0].out, correct_outputs.items[0])) {
                    try diff.append(.{ group.items[0].out, correct_outputs.items[0] });
                }
            } else {
                if (!std.mem.eql(u8, group.items[4].out, correct_outputs.items[4])) {
                    try diff.append(.{ group.items[4].out, correct_outputs.items[4] });
                } else if (!std.mem.eql(u8, group.items[3].out, correct_outputs.items[3])) {
                    try diff.append(.{ group.items[3].out, correct_outputs.items[3] });
                } else if (!std.mem.eql(u8, group.items[0].out, correct_outputs.items[0])) {
                    try diff.append(.{ group.items[0].out, correct_outputs.items[0] });
                } else {
                    var s1 = [_][]const u8{ group.items[1].out, group.items[2].out };
                    std.sort.insertion([]const u8, &s1, {}, compareStrings);
                    var s2 = [_][]const u8{ correct_outputs.items[1], correct_outputs.items[2] };
                    std.sort.insertion([]const u8, &s2, {}, compareStrings);
                    if (!std.mem.eql(u8, s1[0], s2[0]) and !std.mem.eql(u8, s1[1], s2[1])) {
                        try diff.append(.{ s1[0], s2[0] });
                        try diff.append(.{ s1[1], s2[1] });
                    }
                }
            }
            try wrong_outputs.appendSlice(diff.items);
        }

        return try wrong_outputs.toOwnedSlice();
    }

    fn contains(group: std.ArrayList(Gate), gate: Gate) bool {
        for (group.items) |g| {
            if (g.eql(gate)) {
                return true;
            }
        }
        return false;
    }

    fn remove(group: *std.ArrayList(Gate), gate: Gate) !void {
        for (group.items, 0..) |g, i| {
            if (g.eql(gate)) {
                _ = group.orderedRemove(i);
                return;
            }
        }
        return error.InvalidInput;
    }

    fn extractSwap(
        group: *std.ArrayList(Gate),
        name: []const u8,
        gate_type: GateOp,
        start_index: usize,
        dest_index: usize,
    ) !void {
        var index: usize = undefined;
        for (group.items, 0..) |gate, i| {
            if (i >= start_index and (name.len == 0 or gate.in1[0] == name[0]) and gate.op == gate_type) {
                index = i;
                break;
            }
        }
        const x = group.items[dest_index];
        group.items[dest_index] = group.items[index];
        group.items[index] = x;
    }

    fn twoDigitNumberString(n: u64) ![2]u8 {
        var buf: [2]u8 = undefined;
        if (n < 10) {
            _ = try std.fmt.bufPrint(&buf, "0{d}", .{n});
        } else {
            _ = try std.fmt.bufPrint(&buf, "{d}", .{n});
        }

        return buf;
    }

    fn keyInGate(key: []const u8, gate: Gate) bool {
        return std.mem.eql(u8, key, gate.in1) or
            std.mem.eql(u8, key, gate.in2) or
            std.mem.eql(u8, key, gate.out);
    }
};

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}
