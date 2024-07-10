const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;

    const tracer_dep = b.dependency("zig_tracer", .{});
    const tracer_mod = tracer_dep.module("tracer");
    const xml_mod = b.addModule("zig-xml", .{
        .root_source_file = b.path("mod.zig"),
        .imports = &.{
            .{ .name = "tracer", .module = tracer_mod },
        },
    });

    {
        const exe = b.addExecutable(.{
            .name = "bench",
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = mode,
        });
        exe.root_module.addImport("xml", xml_mod);
        exe.linkLibC();

        const run_exe = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_exe.addArgs(args);
        }

        const run_step = b.step("run", "Run benchmark");
        run_step.dependOn(&run_exe.step);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("test.zig"),
        .target = target,
        .optimize = mode,
    });
    unit_tests.root_module.addImport("xml", xml_mod);

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
