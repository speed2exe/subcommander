const std = @import("std");
const subcommander = @import("subcommander");

test "match 1 command" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .execute = hello,
    };
    try mycommands.run(&.{"hello"});
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"world"}));
}

test "no execute fn" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
    };
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"hello"}));
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
    try mycommands.run(&.{ "hello", "world" });
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{ "hello", "baz" }));
}

test "hello world --param" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .subcommands = &.{.{
            .match = "world",
            .execute = helloWorld,
        }},
        .flags = &.{.{
            .long = "param",
        }},
    };
    try mycommands.run(&.{ "hello", "--param", "world" });
}

fn helloWorld(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name)) catch unreachable;
}

fn helloFoo(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name)) catch unreachable;
}

fn hello(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
}
