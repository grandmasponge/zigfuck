const std = @import("std");

pub const Tokens = enum {
    Plus,
    Minus,
    Comma,
    Dot,
    GreaterThan,
    LessThan,
    LeftBracket,
    RightBracket,
    EOF,
};

pub const Lexer = struct {
    tokens: std.ArrayList(Tokens),

    pub fn Tokenize(contents: []u8, allocator: std.mem.Allocator) !Lexer {
        var tokens = std.ArrayList(Tokens).init(allocator);

        for (contents) |value| {
            switch (value) {
                '+' => {
                    try tokens.append(Tokens.Plus);
                },
                '-' => {
                    try tokens.append(Tokens.Minus);
                },
                '.' => {
                    try tokens.append(Tokens.Dot);
                },
                '>' => {
                    try tokens.append(Tokens.GreaterThan);
                },
                '<' => {
                    try tokens.append(Tokens.LessThan);
                },
                '[' => {
                    try tokens.append(Tokens.LeftBracket);
                },
                ']' => {
                    try tokens.append(Tokens.RightBracket);
                },
                else => {
                    if (value == '\n') {
                        continue;
                    } else if (value == ' ') {
                        continue;
                    }
                    return error.InvalidCharater;
                },
            }
        }

        try tokens.append(Tokens.EOF);

        return Lexer{
            .tokens = tokens,
        };
    }
};
