const std = @import("std");
const lexer = @import("./lexer.zig");
const parser = @import("./parser.zig");
const interpreter = @import("./intepreter.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    //skip the start arg
    _ = args.next();

    const filename = args.next();

    if (filename == null) {
        printHelp();
        return error.wrongArgs;
    }

    const file_contents = try openFile(filename.?, allocator);
    defer allocator.free(file_contents);

    var lex = try lexer.Lexer.Tokenize(file_contents, allocator);
    defer lex.tokens.deinit();

    var parse = parser.Parser.init(lex.tokens, allocator);
    defer parse.actions.deinit();
    try parse.parse();

    try interpreter.interpret(parse.actions);
}

pub fn openFile(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.openFileAbsolute(filename, .{ .mode = .read_only });
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    return contents;
}

pub fn printHelp() void {
    // print help stuff
}
