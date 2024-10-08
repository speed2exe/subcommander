const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

pub const RunError = error{
    CommandNotFound,
    FlagNotFound,
};

/// represents all possible commands
pub const Command = struct {
    match: ?[*:0]const u8 = null,
    flags: []const Flags = &.{},
    subcommands: []const Command = &.{},
    description: []const u8 = &.{},
    execute: ?fn (input: *const InputCommand) void = null,

    pub fn run(self: Command, args: []const [*:0]const u8) RunError!void {
        var input: InputCommand = .{ .name = undefined };
        try self.runCommandRecursive(
            args,
            &input,
            &input,
        );
    }

    fn executeCommand(cmd: Command, input: *const InputCommand) RunError!void {
        const exeFn = cmd.execute orelse {
            std.log.warn("execute function not found for command:", .{});
            input.debugPrintCommandRecursive();
            return error.CommandNotFound;
        };

        exeFn(input);
    }

    fn runCommandRecursive(
        self: Command,
        remain_args: []const [*:0]const u8,
        root: *InputCommand,
        current: *InputCommand,
    ) RunError!void {
        if (remain_args.len == 0) return self.executeCommand(root);

        var modified_args = remain_args;
        const next_arg = modified_args[0];
        if (self.match) |match| {
            if (memEqlSentinel(match, next_arg)) {
                current.name = next_arg;
                modified_args = modified_args[1..];
            }
        }

        return self.runFlagsRecursive(modified_args, root, current);
    }

    fn runSubCommandRecursive(
        self: Command,
        remain_args: []const [*:0]const u8,
        root: *InputCommand,
        current: *InputCommand,
    ) RunError!void {
        inline for (self.subcommands) |subcommand| {
            var child: InputCommand = .{ .name = undefined };
            current.next = &child;
            const done = blk: {
                subcommand.runCommandRecursive(
                    remain_args,
                    root,
                    &child,
                ) catch |err| {
                    std.log.debug("subcommand rec error: {any}\n", .{err});
                    break :blk false;
                };
                break :blk true;
            };
            if (done) return;
        }
        return error.CommandNotFound;
    }

    fn runFlagsRecursive(
        self: Command,
        remain_args: []const [*:0]const u8,
        root: *InputCommand,
        current: *InputCommand,
    ) RunError!void { // TODO: remove anyerror
        if (remain_args.len == 0) return self.executeCommand(root);

        var modified_args = remain_args;

        var next_arg = modified_args[0];
        if (next_arg[0] == '-') {
            next_arg = next_arg[1..];
            var is_long = false;
            if (next_arg[0] == '-') {
                next_arg = next_arg[1..];
                is_long = true;
            }

            // get input flag name and value
            var input_flag_name: []const u8 = undefined;
            var value: ?[*:0]const u8 = undefined;
            const eql_idx = idxOfPosSentinel(next_arg, '=');
            if (eql_idx) |idx| {
                input_flag_name = next_arg[0..idx];
                value = next_arg[idx + 1 ..];
            } else {
                input_flag_name = std.mem.span(next_arg);
                value = null;
            }

            // find flag
            inline for (self.flags) |flag| {
                const flag_name_opt = if (is_long) flag.long else flag.short;
                if (flag_name_opt) |flag_name| {
                    if (memEqlSentinelVsSlice(flag_name, input_flag_name)) {
                        var input_flag: InputFlag = .{
                            .name = flag.long,
                            .value = value,
                            .prev = current.flag,
                        };
                        current.flag = &input_flag;
                        return self.runCommandRecursive(
                            modified_args[1..],
                            root,
                            current,
                        );
                    }
                }
            }

            std.log.warn("flag not found: {s}", .{input_flag_name});
            return error.FlagNotFound;
        }

        return self.runSubCommandRecursive(remain_args, root, current);
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

/// Parsed input
pub const InputCommand = struct {
    name: [*:0]const u8,
    flag: ?*InputFlag = null,
    next: ?*InputCommand = null,

    /// Iterate over flags for current command
    pub fn flagIter(self: *const InputCommand) InputFlagIterator {
        return .{ .flag = self.flag };
    }

    /// Recursively Iterate over flags for current command and next commands
    pub fn flagIterRec(self: *const InputCommand) InputFlagIteratorRecursive {
        return .{ .command = self, .flag = self.flag };
    }

    fn debugPrintCommandRecursive(self: *const InputCommand) void {
        std.debug.print("{s} ", .{self.name});
        const next = self.next orelse return std.debug.print("\n", .{});
        std.debug.print("-> ", .{});
        next.debugPrintCommandRecursive();
    }
};

pub const InputFlag = struct {
    name: [*:0]const u8, // long name
    value: ?[*:0]const u8 = null,
    prev: ?*InputFlag = null,
};

pub const InputFlagIterator = struct {
    flag: ?*const InputFlag,

    pub fn next(self: *InputFlagIterator) ?*const InputFlag {
        const current = self.flag orelse return null;
        self.flag = current.prev;
        return current;
    }
};

pub const InputFlagIteratorRecursive = struct {
    command: *const InputCommand,
    flag: ?*const InputFlag,

    pub fn next(self: *InputFlagIteratorRecursive) ?*const InputFlag {
        const current = self.flag orelse {
            const next_command = self.command.next orelse return null;
            self.command = next_command;
            self.flag = next_command.flag;
            return self.next();
        };
        self.flag = current.prev;
        return current;
    }
};

fn memEqlSentinel(a: [*:0]const u8, b: [*:0]const u8) bool {
    var i: usize = 0;
    while (true) : (i += 1) {
        const a_val = a[i];
        const b_val = b[i];
        if (a_val != b_val) return false;
        if (a_val == 0) return true;
    }
}

fn memEqlSentinelVsSlice(a: [*:0]const u8, b: []const u8) bool {
    for (b, 0..) |b_val, i| {
        const a_val = a[i];
        if (a_val != b_val) return false;
        if (a_val == 0) return false;
    }
    return a[b.len] == 0;
}

fn idxOfPosSentinel(haystack: [*:0]const u8, needle: u8) ?usize {
    var i: usize = 0;
    while (true) : (i += 1) {
        const val = haystack[i];
        if (val == 0) return null;
        if (val == needle) return i;
    }
}

// TODO: suggestion, help
