const std = @import("std");
const subcommander = @import("subcommander");

test {
    const mycommands: subcommander.Command = .{};
    try mycommands.run(&.{"hello"});

    // try subcommander.command(.{
    //     .flags = &.{
    //         .{
    //             .short = "h",
    //             .long = "help",
    //             .description = "Prints help information",
    //             .type = @typeInfo(bool),
    //             .default = @constCast(&false),
    //         },
    //     },
    //     .subs = &.{
    //         .{},
    //     },
    //     .exec = begin,
    // });
}

fn begin(input: subcommander.Input) !void {
    _ = input;
    std.debug.print("Hello, world!\n", .{});
}
