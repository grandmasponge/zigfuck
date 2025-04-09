const std = @import("std");
const parser = @import("./parser.zig");

const RuntimeError = error{ OutofMemory, InputError, OutofBounds, UnexpectedAction };

pub fn interpret(program: std.ArrayList(parser.Action)) RuntimeError!void {
    var index: u32 = 0;
    var tape = std.mem.zeroes([1000]u8);
    for (program.items) |actions| {
        try loop(actions, &index, &tape);
    }
}

pub fn loop(action: parser.Action, index: *u32, tape: *[1000]u8) RuntimeError!void {
    if (action == .Loop) {
        const items = action.Loop;
        while (tape.*[index.*] != 0) {
            for (items) |instruction| {
                try loop(instruction, index, tape);
            }
        }
    } else {
        try takeAction(action, index, tape);
    }
}

pub fn takeAction(action: parser.Action, index: *u32, tape: *[1000]u8) RuntimeError!void {
    switch (action) {
        .Add => {
            const current = tape.*[index.*];
            if (current == 255) {
                tape.*[index.*] = 0;
            } else {
                tape.*[index.*] = tape.*[index.*] + 1;
            }
        },
        .Sub => {
            const current = tape.*[index.*];
            if (current == 0) {
                tape.*[index.*] = 255;
            } else {
                tape.*[index.*] = tape.*[index.*] - 1;
            }
        },
        .Output => {
            const current = tape.*[index.*];
            OutputByte(current);
        },
        .TakeInput => {
            const input = try InputByte();
            tape.*[index.*] = input;
        },
        .MoveCellR => {
            index.* += 1;
        },
        .MoveCellL => {
            index.* -= 1;
        },
        else => {
            return RuntimeError.UnexpectedAction;
        },
    }
}

pub fn OutputByte(byte: u8) void {
    std.debug.print("{c}", .{byte});
}

pub fn InputByte() RuntimeError!u8 {
    const stdin = std.io.getStdIn().reader();

    const byte = stdin.readByte() catch {
        return RuntimeError.InputError;
    };

    return byte;
}
