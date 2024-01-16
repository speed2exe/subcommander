const std = @import("std");
const subcommander = @import("subcommander");

test {
    try subcommander.command(.{
        .flags = &.{
            .{
                .short = "h",
                .long = "help",
                .description = "Prints help information",
                .type = bool,
                .default_value = false,
            },
        },
        .subs = &.{
            .{},
        },
        .exec = begin,
    });
}

fn begin(args: anytype) !void {
    _ = args;
    std.debug.print("begin\n", .{});
}
