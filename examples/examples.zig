const std = @import("std");
const subcommander = @import("subcommander");

test "match 1 command" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .execute = hello,
    };
    try mycommands.run(&.{"hello"});
}

test "did not match command " {
    const mycommands: subcommander.Command = .{
        .match = "hello",
    };
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"world"}));
}

test "match 2 and execute" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .subcommands = &.{.{
            .match = "world",
            .execute = helloWorld,
        }},
    };
    try mycommands.run(&.{ "hello", "world" });
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"hello"}));
}

test "match split path and execute" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .subcommands = &.{ .{
            .match = "world",
            .execute = helloWorld,
        }, .{
            .match = "foo",
            .execute = helloFoo,
        } },
    };
    try mycommands.run(&.{ "hello", "foo" });
}

fn helloWorld(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.prev.?.name)) catch unreachable;
}

fn helloFoo(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.prev.?.name)) catch unreachable;
}

fn hello(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
}
