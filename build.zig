const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const obj = b.addObject(.{
        .name = "main.c",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    obj.addIncludePath(.{ .cwd_relative = "raylib/src/" });

    const obj_install = b.addInstallArtifact(obj, .{ .dest_dir = .{ .override = .prefix } });
    b.getInstallStep().dependOn(&obj_install.step);
}
