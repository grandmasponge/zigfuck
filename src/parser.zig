const std = @import("std");
const lexer = @import("./lexer.zig");

const ParserError = error{
    OutOfBounds,
    EOF,
    UnexpectedToken,
    AppendError,
    OutOfMemory,
};

pub const Parser = struct {
    tokens: std.ArrayList(lexer.Tokens),
    actions: std.ArrayList(Action),
    allocator: std.mem.Allocator,
    index: usize = 0,

    pub fn init(tokens: std.ArrayList(lexer.Tokens), allocator: std.mem.Allocator) !Parser {
        return Parser{
            .tokens = try tokens.clone(),
            .actions = std.ArrayList(Action).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.tokens.deinit();
        self.actions.deinit();
    }

    pub fn getActions(self: *Parser) std.ArrayList(Action) {
        return self.actions;
    }

    fn current(self: *Parser) lexer.Tokens {
        if (self.index >= self.tokens.items.len) return lexer.Tokens.EOF;
        return self.tokens.items[self.index];
    }

    fn next(self: *Parser) void {
        self.index += 1;
    }

    fn prev(self: *Parser) lexer.Tokens {
        const prev_index = if (self.index == 0) 0 else self.index - 1;
        return self.tokens.items[prev_index];
    }

    fn atEnd(self: *Parser) bool {
        return self.current() == lexer.Tokens.EOF;
    }

    pub fn parse(self: *Parser) !void {
        while (!self.atEnd()) {
            try self.actions.append(try self.program());
        }
    }

    fn program(self: *Parser) ParserError!Action {
        return try self.block();
    }

    fn block(self: *Parser) ParserError!Action {
        if (self.current() == lexer.Tokens.LeftBracket) {
            self.next();
            var items = std.ArrayList(Action).init(self.allocator);
            defer items.deinit();

            while (self.current() != lexer.Tokens.RightBracket and !self.atEnd()) {
                items.append(try self.program()) catch {
                    return ParserError.OutOfMemory;
                };
            }

            if (self.atEnd()) return ParserError.UnexpectedToken;
            self.next();

            return Action{
                .Loop = try items.toOwnedSlice(),
            };
        }
        return try self.symbols();
    }

    fn symbols(self: *Parser) !Action {
        return switch (self.current()) {
            lexer.Tokens.Plus => blk: {
                self.next();
                break :blk Action{ .Add = 1 };
            },
            lexer.Tokens.Minus => blk: {
                self.next();
                break :blk Action{ .Sub = 1 };
            },
            lexer.Tokens.Dot => blk: {
                self.next();
                break :blk Action{ .Output = 1 };
            },
            lexer.Tokens.Comma => blk: {
                self.next();
                break :blk Action{ .TakeInput = 1 };
            },
            lexer.Tokens.LessThan => blk: {
                self.next();
                break :blk Action{ .MoveCellL = 1 };
            },
            lexer.Tokens.GreaterThan => blk: {
                self.next();
                break :blk Action{ .MoveCellR = 1 };
            },
            else => ParserError.UnexpectedToken,
        };
    }
};

const ActionType = enum {
    Add,
    Sub,
    Output,
    MoveCellR,
    MoveCellL,
    TakeInput,
    Loop,
};

pub const Action = union(ActionType) {
    Add: u8,
    Sub: u8,
    Output: u8,
    MoveCellR: u32,
    MoveCellL: u32,
    TakeInput: u8,
    Loop: []Action,
};
