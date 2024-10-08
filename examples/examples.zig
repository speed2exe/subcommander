const std = @import("std");
const subcommander = @import("subcommander");

fn hello(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
}
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

fn helloWorld(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name)) catch unreachable;
}
fn helloFoo(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name)) catch unreachable;
}
test "hello world/foo" {
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
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"hello"}));
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{ "hello", "baz" }));
}

fn helloWorldParam(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name)) catch unreachable;
    const param = input.flags.?;
    std.testing.expectEqualSlices(u8, "param", std.mem.span(param.name)) catch unreachable;
    std.testing.expectEqual(null, param.value) catch unreachable;
    std.testing.expectEqual(null, param.prev) catch unreachable;
}
fn helloFooParam(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name)) catch unreachable;
    const b_param = input.next.?.flags.?;
    std.testing.expectEqualSlices(u8, "b_param", std.mem.span(b_param.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "goodbye", std.mem.span(b_param.value.?)) catch unreachable;
    const a_param = b_param.prev.?;
    std.testing.expectEqualSlices(u8, "a_param", std.mem.span(a_param.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "", std.mem.span(a_param.value.?)) catch unreachable;
    std.testing.expectEqual(null, a_param.prev) catch unreachable;
}
test "hello world --param" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .subcommands = &.{
            .{
                .match = "world",
                .execute = helloWorldParam,
            },
            .{
                .match = "foo",
                .execute = helloFooParam,
                .flags = &.{
                    .{
                        .short = "a",
                        .long = "a_param",
                    },
                    .{
                        .short = "b",
                        .long = "b_param",
                    },
                },
            },
        },
        .flags = &.{.{
            .short = "p",
            .long = "param",
        }},
    };
    try mycommands.run(&.{ "hello", "--param", "world" });
    try mycommands.run(&.{ "hello", "-p", "world" });
    try mycommands.run(&.{ "hello", "foo", "-a=", "-b=goodbye" });
}
