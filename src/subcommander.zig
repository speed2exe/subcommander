const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

/// represents all possible commands
pub const Command = struct {
    match: ?[*:0]const u8 = null,
    flags: []const Flags = &.{},
    subcommands: []const Command = &.{},
    description: []const u8 = &.{},
    execute: ?fn (input: *const InputCommand) void = null,

    pub fn run(
        self: Command,
        args: []const [*:0]const u8,
    ) !void {
        var input: InputCommand = .{ .name = undefined };
        try self.run_rec_command(
            // allocator,
            args,
            &input,
            &input,
        );
    }

    fn executeCmd(cmd: Command, input: *const InputCommand) !void {
        // TODO: pretty print hints
        const exeFn = cmd.execute orelse return error.CommandNotFound;
        exeFn(input);
    }

    fn run_rec_command(
        self: Command,
        remain_args: []const [*:0]const u8,
        parent: *InputCommand,
        current: *InputCommand,
    ) !void {
        if (remain_args.len == 0) return self.executeCmd(parent);

        var modified_args = remain_args;
        const next_arg = modified_args[0];
        if (self.match) |match| {
            if (memEqlSentinelStr(match, next_arg)) {
                current.name = next_arg;
                modified_args = modified_args[1..];
            }
        }

        return self.run_rec_flags(modified_args, parent, current);
    }

    fn run_rec_sub_command(
        self: Command,
        remain_args: []const [*:0]const u8,
        parent: *InputCommand,
        current: *InputCommand,
    ) !void {
        inline for (self.subcommands) |subcommand| {
            var child: InputCommand = .{ .name = undefined };
            current.prev = &child;
            const done = blk: {
                subcommand.run_rec_command(
                    remain_args,
                    parent,
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

    fn run_rec_flags(
        self: Command,
        remain_args: []const [*:0]const u8,
        parent: *InputCommand,
        current: *InputCommand,
    ) !void {
        if (remain_args.len == 0) return self.executeCmd(parent);

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
            const eql_idx = idxOfPosSentinelStr(next_arg, '=');
            if (eql_idx) |idx| {
                input_flag_name = next_arg[0..idx];
                value = next_arg[idx + 1 ..];
            } else {
                input_flag_name = std.mem.span(next_arg);
                value = null;
            }

            // find flag
            for (self.flags) |flag| {
                const target_name = if (is_long) flag.long else flag.short;
                if (memEqlSentinelStr(target_name, input_flag_name)) {
                    current.flags = .{
                        .name = flag.long,
                        .value = value,
                        .prev = current.flags,
                    };
                    return self.run_rec_command(
                        modified_args[1..],
                        parent,
                        current,
                    );
                }
            }

            std.log.err("flag not found: {s}\n", .{input_flag_name});
            return error.FlagNotFound;
        }

        return self.run_rec_sub_command(remain_args, parent, current);
    }

    pub fn help() !void {
        return error.NotImplemented;
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
    flags: ?*InputFlag = null,
    prev: ?*InputCommand = null,
};

pub const InputFlag = struct {
    name: [*:0]const u8, // long name
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

fn idxOfPosSentinelStr(haystack: [*:0]const u8, needle: u8) ?usize {
    var i: usize = 0;
    while (true) : (i += 1) {
        const val = haystack[i];
        if (val == 0) return null;
        if (val == needle) return i;
    }
}

// TODO: suggestion, help
