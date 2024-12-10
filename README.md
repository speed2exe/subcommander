# Subcommander
- command line parser with sub commands

## Features
- No heap allocation
- Declarative

## Add as dependency to your Zig project

- `build.zig.zon`
```
.{
    .dependencies = .{
        .subcommander = .{
            // use a commit hash
            .url = "https://github.com/speed2exe/subcommander/archive/52c42f27cc888d3a9a0fbda6889b8a931ca673be.tar.gz",
            // upon compilation, you will get an error with the correct hash,
            // replace the following hash with the correct hash
            .hash = "1220cea02c171a09873b197687c80a0e1a632e58ab99b779d2d5b0090c116efe5348",
        },
    },
}
```

- `build.zig`
```zig
    //...
    const subcommander_dep = b.dependency("subcommander", .{});
    const subcommander = subcommander_dep.module("subcommander");
    exe.addModule("subcommander", subcommander);
    //...
```

## Compatibility
- not compatible with windows (yet)

## Usage

```zig
const std = @import("std");
const subcommander = @import("subcommander");

fn main() !void {
    // build your commands and flags here
    // define what flags to parse
    const mycommands: subcommander.Command = .{
        // if not specified, will parse the flags, then subcommands (if any)
        // this will be the name of the program.
        // e.g. "greet --name=world"
        // usually you would want to skip this (dont specify) since the name of executable will not be consistent
        // for majority of use cases.
        //
        // .match = "greet",

        // fn to execute when the command is matched
        .execute = greetHandler,

        // flags are local to the command "greet"
        .flags = &.{
            .{
                .short = "n",
                .long = "name",
                .description = "name to greet",
            },
            .{
                .short = "h",
                .long = "help",
                .description = "print help",
            },
        },

        // subcommands are command that follows after `match`
        .subcommands = &.{
            .{
                .match = "tom",
                .execute = greetTomHandler,
                .flags = &.{
                    // addition flags after "tom"
                    // e.g. args; "greet tom --tomflag=5 ..."
                    //
                },
            },
        },

    };

    // run commands with args from the command line
    // Flag value type: ?[*:0]const u8
    // Success:
    // ./mygreet --name=world    # Flag value for name: "world"
    // ./mygreet --name=         # Flag value for name: ""
    // ./mygreet --name          # Flag value for name: null
    // ./mygreet
    //
    // We are skipping the first argument since it is the name of the program
    // therefore flags are parsed first, then subcommands
    try mycommands.run(std.os.argv[1..]);
}

// function signature for greetHandler
fn greetHandler(input: *const subcommander.InputCommand) void {
    // get the command that was matched
    std.debug.print("{s}", .{input.name.?}); // prints "greet"

    // iterate over the flags for "greet"
    var flag_iter = input.flagIterRec();
    while (flag_iter.next()) |flag| {
        const value: ?[*:0]const u8 = flag.value;
        // do something with the flag
    }

    // call next() to get the subcommand (if any)
    if (input.next) |next_input| {
        // `next_input` is same type as `input`
    }
}

```
