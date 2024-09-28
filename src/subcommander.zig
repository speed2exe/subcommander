const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

/// Declaration
pub fn notImplemented(_: *const InputCommand) void {
    std.log.debug("this command is not implemented\n", .{});
    return;
}

/// represents all possible commands
pub const Command = struct {
    match: ?[*:0]const u8 = null,
    flags: []const Flags = &.{},
    subcommands: []const Command = &.{},
    description: []const u8 = &.{},
    execute: fn (input: *const InputCommand) void = notImplemented,

    pub fn run(
        self: Command,
        args: []const [*:0]const u8,
    ) !void {
        var input: InputCommand = .{ .name = undefined };
        try self.run_rec(
            // allocator,
            args,
            &input,
            &input,
        );
    }

    fn run_rec(
        self: Command,
        remain_args: []const [*:0]const u8,
        parent: *InputCommand,
        current: *InputCommand,
    ) !void {
        if (remain_args.len == 0) return self.execute(parent);

        var modified_args = remain_args;

        // match command
        const next_arg = modified_args[0];
        if (self.match) |match| {
            if (memEqlSentinelStr(match, next_arg)) {
                current.name = next_arg;
                modified_args = modified_args[1..];
            }
        }

        // match flags
        // TODO: impl
        //
        //

        if (modified_args.len == 0) {
            return self.execute(current);
        }

        inline for (self.subcommands) |subcommand| {
            var child: InputCommand = .{ .name = undefined };
            current.next = &child;
            const done = blk: {
                subcommand.run_rec(
                    remain_args,
                    parent,
                    &child,
                ) catch |err| {
                    std.log.debug("subcommand rec error: {}\n", .{err});
                    break :blk false;
                };
                break :blk true;
            };
            if (done) return;
        }
        return error.CommandNotFound;
    }
};

// supported formats(long):
// --param=value
// --param=
// --param
// short is same as long but uses single dash
// -p=value
// -p=
// -p
pub const Flags = struct {
    short: ?[*:0]const u8 = null,
    long: [*:0]const u8,
    description: [*:0]const u8 = "",
};

// flags
pub const MyFlag = union(enum) {
    param1: bool,
    param2: i8,
};

/// Parsed input
pub const InputCommand = struct {
    name: [*:0]const u8,
    flags: ?*InputFlag = null,
    next: ?*InputCommand = null,
};

pub const InputFlag = struct {
    name: [*:0]const u8,
    value: ?[*:0]const u8 = null,
    next: ?*InputFlag = null,
};

fn memEqlSentinelStr(a: [*:0]const u8, b: [*:0]const u8) bool {
    var i: usize = 0;
    while (true) : (i += 1) {
        const a_val = a[i];
        const b_val = b[i];
        if (a_val != b_val) return false;
        if (a_val == 0) return true;
    }
}
