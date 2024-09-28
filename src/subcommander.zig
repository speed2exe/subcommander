const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

/// Declaration
pub fn noOp(_: *const InputCommand) void {
    std.log.debug("noOp\n", .{});
    return;
}

/// represents all possible commands
pub const Command = struct {
    match: ?[]const u8 = null,
    flags: []const Flags = &.{},
    subcommands: []const Command = &.{},
    description: []const u8 = &.{},
    execute: fn (input: *const InputCommand) void = noOp,

    pub fn run(
        self: Command,
        args: []const [*:0]const u8,
    ) !void {
        var input: InputCommand = .{};
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
        if (self.match) |match| {
            if (std.mem.eql(u8, match, modified_args[0])) {
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

        for (self.subcommands) |subcommand| {
            var child: InputCommand = .{};
            current.next = &child;
            try subcommand.run_rec(
                remain_args,
                parent,
                &child,
            ) catch |err| {
                std.log.debug("subcommand rec error: {}\n", .{err});
                continue;
            };
            return;
        }
        std.log.err("did not match any commands\n", .{});
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
    short: ?[]const u8 = null,
    long: []const u8,
    description: []const u8 = "",
};

// flags
pub const MyFlag = union(enum) {
    param1: bool,
    param2: i8,
};

/// Parsed input
pub const InputCommand = struct {
    name: ?[]const u8 = null,
    flags: ?*InputFlag = null,
    next: ?*InputCommand = null,
};

pub const InputFlag = struct {
    name: []const u8,
    value: ?[]const u8 = null,
    next: ?*InputFlag = null,
};
