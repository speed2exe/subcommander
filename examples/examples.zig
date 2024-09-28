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
