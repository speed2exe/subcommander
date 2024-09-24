const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

/// Declaration
pub fn notImplemented(_: Input) !void {
    return error.NotImplemented;
}

/// represents all possible commands
pub const Command = struct {
    match: Match = .AnyNonEmpty,
    flags: []const Flags = &.{},
    subcommands: []const Command = &.{},
    description: []const u8 = &.{},
    execute: fn (input: Input) anyerror!void = notImplemented,

    pub fn run(self: Command, inputs: []const []const u8) !void {
        _ = inputs;
        const i: Input = .{};
        try self.execute(i);
    }
};

pub const Match = union(enum) {
    Exact: []const u8,
    Prefix: []const u8,
    AnyNonEmpty,

    // Not supported yet
    // Pattern: []const u8,
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
    short: ?[]const u8,
    long: []const u8,
    description: ?[]const u8,
};

// flags
pub const MyFlag = union(enum) {
    param1: bool,
    param2: i8,
};

/// Parsed input
pub const Input = struct {
    commands: []const InputCommand = &.{},
};

pub const InputCommand = struct {
    name: []const u8,
    flags: []const InputFlag = &.{},
};

pub const InputFlag = struct {
    name: []const u8,
    value: ?[]const u8,
};
