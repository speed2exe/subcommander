const std = @import("std");
const subcommander = @import("subcommander");

test "match 1 command" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
    };
    try mycommands.run(&.{"hello"});
}

test "did not match command " {
    const mycommands: subcommander.Command = .{
        .match = "hello",
    };
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"world"}));
}

fn exeFn1(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name)) catch unreachable;
}

test "match 2 and execute" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .subcommands = &.{.{
            .match = "world",
            .execute = exeFn1,
        }},
    };
    try mycommands.run(&.{"hello"});
}
