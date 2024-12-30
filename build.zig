const std = @import("std");
const Allocator = std.mem.Allocator;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.debug.print("Memory leak detected\n", .{});
    }
    generateDaysFile(allocator, "./src") catch {};
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const clap = b.dependency("clap", .{});
    const mvzr = b.dependency("mvzr", .{});

    const lib = b.addStaticLibrary(.{
        .name = "aoc2024",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addImport("mvzr", mvzr.module("mvzr"));
    lib.root_module.addImport("clap", clap.module("clap"));

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // exe.linkLibC();
    // // This declares intent for the executable to be installed into the
    // // standard location when the user invokes the "install" step (the default
    // // step when running `zig build`).
    // b.installArtifact(exe);

    const runner = b.addExecutable(.{
        .name = "aocRunner",
        .root_source_file = b.path("src/runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    runner.root_module.addImport("mvzr", mvzr.module("mvzr"));
    runner.root_module.addImport("clap", clap.module("clap"));
    runner.linkLibC();
    b.installArtifact(runner);

    const exe = b.addExecutable(.{
        .name = "aoc2024",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("mvzr", mvzr.module("mvzr"));
    exe.root_module.addImport("clap", clap.module("clap"));
    exe.linkLibC();
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(runner);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn generateDaysFile(allocator: Allocator, dir: []const u8) !void {
    var d = try std.fs.cwd().openDir(dir, .{});
    const filename = "_days.zig";
    d.deleteFile(filename) catch {};
    const file = try d.createFile(filename, .{});
    defer file.close();
    try file.writeAll("pub const common = @import(\"common.zig\");\n");

    var day_list = std.AutoArrayHashMap(usize, []const u8).init(allocator);
    defer {
        for (day_list.values()) |v| allocator.free(v);
        day_list.deinit();
    }

    for (1..26) |i| {
        const day_filename = try std.fmt.allocPrint(
            allocator,
            "day{d}/day.zig",
            .{i},
        );
        defer allocator.free(day_filename);

        _ = d.statFile(day_filename) catch continue;

        const id = try std.fmt.allocPrint(allocator, "day{d}", .{i});
        try file.writer().print(
            "pub const {s} = @import(\"{s}\");\n",
            .{ id, day_filename },
        );

        try day_list.put(i, id);
    }

    try file.writeAll("\n");

    for (day_list.keys()) |k| {
        const str = day_list.get(k).?;
        try file.writer().print(
            "pub const {s}_work = common.Worker{{ .day = \"{d}\", .parse = @ptrCast(&{s}.parse), .part1 = @ptrCast(&{s}.part1), .part2 = @ptrCast(&{s}.part2), }};\n",
            .{ str, k, str, str, str },
        );
    }
    try file.writeAll("\n");

    try file.writeAll("pub const Day = enum {");
    for (day_list.values()) |v| {
        try file.writer().print("{s},", .{v});
    }
    try file.writeAll("};\n\n");

    try file.writeAll("pub fn getWork(day: Day) common.Worker { return switch (day) { ");
    for (day_list.values()) |v| {
        try file.writer().print(".{s} => {s}_work, ", .{ v, v });
    }
    try file.writeAll("}; }\n");
}
