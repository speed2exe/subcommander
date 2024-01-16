const std = @import("std");
const print = std.debug.print;
const fmt = @import("tree-fmt").defaultFormatter();

pub fn command(sub: anytype) !void {
    const Sub = @TypeOf(sub);
    const sub_ti = @typeInfo(Sub);
    const args: Args(Sub) = undefined;

    try fmt.format(sub, .{});

    switch (sub_ti) {
        .Struct => |s| {
            _ = s;

            // collect all flags
            if (@hasField(Sub, "flags")) {
                const fields = @field(sub, "flags");
                print("flags: {any}\n", .{fields});
            }

            if (@hasField(Sub, "subs")) {
                const fields = @field(sub, "subs");
                print("fields: {any}\n", .{fields});
            }

            if (@hasField(Sub, "exec")) {
                return try sub.exec(&args);
            }

            return error.Unimplemented;
        },
        else => return error.InvalidSubCommand,
    }
}

pub fn Args(comptime Sub: type) type {
    const sub_ti = @typeInfo(Sub);

    switch (sub_ti) {
        .Struct => |s| {
            _ = s;
            // print("s: {any}\n", .{s});
            // if (@hasField(Sub, "flags")) {
            //     const flags_fields = @field(s, "flags");
            //     var arg_fields: [flags_fields.len]std.builtin.Type.StructField = undefined;
            //     for (flags_fields, 0..) |flag_field, i| {
            //         arg_fields[i] = .{
            //             .name = @field(flag_field, "long"),
            //             .type = @field(flag_field, "type"),
            //             .default_value = @field(flag_field, "type"),
            //             // .is_comptime: false,
            //             // .alignment: comptime_int,
            //         };
            //     }
            // }
        },
        else => unreachable,
    }

    return void;
}

pub const SubArgs = struct {
    name: []const u8,
    flags: struct {
        // ...

    },
    sub: ?*const SubArgs,
};

// pub const Sub = struct {
//     flags: []const Flag,
//     subs: []const Sub,
//     run: fn (args: *const Args) anyerror!void,
// };
//
// pub const Flag = struct {
//     name: []const u8,
//     short: []const u8,
//     help: []const u8,
//     value_type: ValueType,
//     default_value: []const u8,
//     required: bool = false,
// };

const ValueType = enum {
    isize,
    usize,

    i8,
    i16,
    i32,
    i64,

    u8,
    u16,
    u32,
    u64,

    f32,
    f64,

    bool,
    string,

    path,
    file,
    dir,
};
