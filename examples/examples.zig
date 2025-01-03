const std = @import("std");
const subcommander = @import("subcommander");

fn hello(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
}
test "match 1 command" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
        .execute = hello,
    };
    try mycommands.run(&.{"hello"});
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"world"}));

    // exhaustively test all possible error cases
    if (mycommands.run(&.{"world"})) unreachable else |run_error| switch (run_error) {
        error.CommandNotFound => {},
        error.FlagNotFound => unreachable,
    }
}

test "no execute fn" {
    const mycommands: subcommander.Command = .{
        .match = "hello",
    };
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{"hello"}));
}

fn helloWorld(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name.?)) catch unreachable;
}
fn helloFoo(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name.?)) catch unreachable;
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
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "world", std.mem.span(input.next.?.name.?)) catch unreachable;
    const param = input.flag.?;
    std.testing.expectEqualSlices(u8, "param", std.mem.span(param.name)) catch unreachable;
    std.testing.expectEqual(null, param.value) catch unreachable;
    std.testing.expectEqual(null, param.prev) catch unreachable;
}
fn helloFooParam(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name.?)) catch unreachable;
    const b_param = input.next.?.flag.?;
    std.testing.expectEqualSlices(u8, "b_param", std.mem.span(b_param.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "goodbye", std.mem.span(b_param.value.?)) catch unreachable;
    const a_param = b_param.prev.?;
    std.testing.expectEqualSlices(u8, "a_param", std.mem.span(a_param.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "", std.mem.span(a_param.value.?)) catch unreachable;
    std.testing.expectEqual(null, a_param.prev) catch unreachable;

    {
        // Using flag iterator for current input
        var flag_iter = input.flagIter();
        while (flag_iter.next()) |flag| {
            if (std.mem.eql(u8, "a_param", std.mem.span(flag.name))) {
                std.testing.expectEqualSlices(u8, "", std.mem.span(flag.value.?)) catch unreachable;
            } else if (std.mem.eql(u8, "b_param", std.mem.span(flag.name))) {
                std.testing.expectEqualSlices(u8, "goodbye", std.mem.span(flag.value.?)) catch unreachable;
            } else {
                std.testing.expect(false) catch unreachable;
            }
        }
    }
}
fn helloFooBar(input: *const subcommander.InputCommand) void {
    std.testing.expectEqualSlices(u8, "hello", std.mem.span(input.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "foo", std.mem.span(input.next.?.name.?)) catch unreachable;
    std.testing.expectEqualSlices(u8, "bar", std.mem.span(input.next.?.next.?.name.?)) catch unreachable;
    {
        // iterate recursively through flags
        var param: ?[*:0]const u8 = undefined;
        var a_param: ?[*:0]const u8 = undefined;
        var b_param: ?[*:0]const u8 = undefined;
        var c_param: ?[*:0]const u8 = undefined;
        var all_flags_iter = input.flagIterRec();
        while (all_flags_iter.next()) |flag| {
            if (std.mem.eql(u8, "param", std.mem.span(flag.name))) {
                param = flag.value;
            } else if (std.mem.eql(u8, "a_param", std.mem.span(flag.name))) {
                a_param = flag.value;
            } else if (std.mem.eql(u8, "b_param", std.mem.span(flag.name))) {
                b_param = flag.value;
            } else if (std.mem.eql(u8, "c_param", std.mem.span(flag.name))) {
                c_param = flag.value;
            } else unreachable;
        }
        std.testing.expectEqualSlices(u8, "123", std.mem.span(param.?)) catch unreachable;
        std.testing.expectEqualSlices(u8, "456", std.mem.span(a_param.?)) catch unreachable;
        std.testing.expectEqualSlices(u8, "789", std.mem.span(b_param.?)) catch unreachable;
        std.testing.expectEqualSlices(u8, "999", std.mem.span(c_param.?)) catch unreachable;
    }
}
test "hello world foo bar" {
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
                .subcommands = &.{
                    .{
                        .match = "bar",
                        .execute = helloFooBar,
                        .flags = &.{
                            .{
                                .short = "c",
                                .long = "c_param",
                            },
                        },
                    },
                    .{ .match = "baz" },
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
    try mycommands.run(&.{ "hello", "-p=123", "foo", "-a=456", "-b=789", "bar", "-c=999" });
    try std.testing.expectError(error.FlagNotFound, mycommands.run(&.{ "hello", "-x=123" }));
    try std.testing.expectError(error.CommandNotFound, mycommands.run(&.{ "hello", "foo", "baz" }));
}

fn noOp(input: *const subcommander.InputCommand) void {
    _ = input;
}

test "match not specified, but sub specified" {
    const mycommands: subcommander.Command = .{
        .subcommands = &.{
            .{ .match = "hello", .execute = noOp },
        },
    };
    _ = try mycommands.run(&.{"hello"});
}

fn nofirstCmdButWithFlags(input: *const subcommander.InputCommand) void {
    std.testing.expectEqual(input.name, null) catch unreachable;
    std.testing.expectEqual(input.flag.?.name, "param") catch unreachable;
    std.testing.expectEqual(input.flag.?.value.?, "3") catch unreachable;
}
test "still able to parse flags" {
    const mycommands: subcommander.Command = .{
        .subcommands = &.{
            .{ .match = "hello", .execute = noOp },
        },
        .flags = &.{
            .{ .short = "p", .long = "param" },
        },
    };
    _ = try mycommands.run(&.{ "--param=3", "hello" });
}

fn assertParamEqual3(input: *const subcommander.InputCommand) void {
    const param = input.flag.?;
    std.testing.expectEqualSlices(u8, "param", std.mem.span(param.name)) catch unreachable;
    std.testing.expectEqualSlices(u8, "3", std.mem.span(param.value.?)) catch unreachable;
}
test "can execute without initial match" {
    const mycommands: subcommander.Command = .{
        .execute = assertParamEqual3,
        .flags = &.{
            .{ .short = "p", .long = "param" },
        },
    };
    _ = try mycommands.run(&.{"--param=3"});
}
