const std = @import("std");

const commandError = error{
    MissingCommand,
    MissingArguments,
    InvalidCommand,
    InvalidArguments,
    OutOfMemory,
};

pub const commandType = enum {
    run,
    flush,
};

pub const commandsAndArguments = struct {
    command: commandType,
    arguments: std.ArrayList([]u8),
};

pub const commandLineArgs = struct {
    pub fn userArguments(iter: *std.process.ArgIterator, allocater: std.mem.Allocator) commandError!commandsAndArguments {
        var arguments = std.ArrayList([]u8).init(allocater);

        const command = iter.next() orelse return commandError.MissingCommand;

        if (std.mem.eql(u8, command, "run")) {
            const filename = iter.next() orelse return commandError.MissingArguments;
            try arguments.append(try allocater.dupe(u8, filename));
            return commandsAndArguments{
                .arguments = arguments,
                .command = .run,
            };
        } else if (std.mem.eql(u8, command, "flush")) {
            const filename = iter.next() orelse return commandError.MissingArguments;
            try arguments.append(try allocater.dupe(u8, filename));
            return commandsAndArguments{
                .command = .flush,
                .arguments = arguments,
            };
        } else {
            return commandError.InvalidCommand;
        }
    }
};

pub fn printCommandHelp() void {}
