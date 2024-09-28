const std = @import("std");

pub fn build(b: *std.Build) void {
    const treefmt = b.dependency("tree_fmt", .{});
    const tree_fmt = treefmt.module("tree-fmt");

    const subcommander = b.addModule("subcommander", .{
        .root_source_file = b.path("./src/subcommander.zig"),
    });
    subcommander.addImport("tree-fmt", tree_fmt);

    const examples = b.addTest(.{
        .root_source_file = b.path("./examples/examples.zig"),
    });
    const run_examples = b.addRunArtifact(examples);
    const run_examples_step = b.step("test", "Run examples");
    run_examples_step.dependOn(&run_examples.step);
    examples.root_module.addImport("subcommander", subcommander);
}
