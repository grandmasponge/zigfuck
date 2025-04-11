const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const interpreter = @import("./intepreter.zig");
const argument = @import("./arguments.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();

    var arg_handeler = argument.commandLineArgs.userArguments(&args, allocator) catch {
        argument.printCommandHelp();
        std.debug.print("[ERROR]  \n", .{});
        return;
    };
    defer arg_handeler.arguments.deinit();

    switch (arg_handeler.command) {
        .run => {
            const filename = arg_handeler.arguments.items[0];

            const contents = try openFile(filename, allocator);
            var tokensizer = lexer.Lexer.Tokenize(contents, allocator) catch {
                std.debug.print("[ERROR] failed to tokenize contents \n", .{});
                return;
            };
            defer tokensizer.deinit();
            var parse = parser.Parser.init(tokensizer.getTokens(), allocator) catch {
                std.debug.print("failed to parse the tokens \n", .{});
                return;
            };
            defer parse.deinit();
            try parse.parse();

            _ = interpreter.interpret(parse.getActions()) catch {
                std.debug.print("runtime error \n", .{});
                return;
            };
        },
        .flush => {
            const filename = arg_handeler.arguments.items[0];

            const contents = try openFile(filename, allocator);
            var tokensizer = lexer.Lexer.Tokenize(contents, allocator) catch {
                std.debug.print("[ERROR] failed to tokenize contents \n", .{});
                return;
            };
            defer tokensizer.deinit();
            var parse = parser.Parser.init(tokensizer.getTokens(), allocator) catch {
                std.debug.print("failed to parse the tokens \n", .{});
                return;
            };
            defer parse.deinit();
            try parse.parse();

            const tape = interpreter.interpret(parse.getActions()) catch {
                std.debug.print("runtime error \n", .{});
                return;
            };

            for (tape) |cell| {
                std.debug.print(" [{d}] ", .{cell});
            }
        },
    }
}

fn validateFile(filename: []const u8) bool {
    if (filename.len > 255) {
        return false;
    }

    var split = std.mem.split(u8, filename, ".");
    while (split.next()) |item| {
        if (split.peek() == null) {
            if (std.mem.eql(u8, item, "zigfuck")) {
                return true;
            } else {
                return false;
            }
        } else {
            continue;
        }
    }

    return false;
}

fn openFile(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = std.fs.cwd().openFile(filename, .{ .mode = .read_only }) catch {
        return error.fileOpenError;
    };
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    return contents;
}
