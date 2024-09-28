const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "and", .keyword_and },
        .{ "break", .keyword_break },
        .{ "do", .keyword_do },
        .{ "else", .keyword_else },
        .{ "elseif", .keyword_elseif },
        .{ "end", .keyword_end },
        .{ "false", .keyword_false },
        .{ "for", .keyword_for },
        .{ "function", .keyword_function },
        .{ "if", .keyword_if },
        .{ "in", .keyword_in },
        .{ "local", .keyword_local },
        .{ "nil", .keyword_nil },
        .{ "not", .keyword_not },
        .{ "or", .keyword_or },
        .{ "repeat", .keyword_repeat },
        .{ "return", .keyword_return },
        .{ "then", .keyword_then },
        .{ "true", .keyword_true },
        .{ "until", .keyword_until },
        .{ "while", .keyword_while },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }

    pub const Tag = enum {
        invalid,
        identifier,
        // not sure about this
        string_literal,
        number_literal,
        eof,
        left_bracket,
        left_bracket_bracket,
        right_bracket,
        right_bracket_bracket,
        left_curly_bracket,
        right_curly_bracket,
        left_paren,
        right_paren,
        comma,
        colon,
        dot,
        semicolon,
        equal,
        plus,
        minus,
        minus_minus,
        asterisk,
        slash,
        caret,
        percent,
        dot_dot,
        dot_dot_dot,
        left_angle_bracket,
        left_angle_bracket_equal,
        right_angle_bracket,
        right_angle_bracket_equal,
        equal_equal,
        tilde_equal,
        octothorpe,
        keyword_and,
        keyword_break,
        keyword_do,
        keyword_else,
        keyword_elseif,
        keyword_end,
        keyword_false,
        keyword_for,
        keyword_function,
        keyword_if,
        keyword_in,
        keyword_local,
        keyword_nil,
        keyword_not,
        keyword_or,
        keyword_repeat,
        keyword_return,
        keyword_then,
        keyword_true,
        keyword_until,
        keyword_while,

        pub fn lexeme(tag: Tag) ?[]const u8 {
            switch (tag) {
                .invalid,
                .identifier,
                .string_literal,
                .number_literal,
                .eof,
                => null,

                .left_bracket => "[",
                .left_bracket_bracket => "[[",
                .right_bracket => "]",
                .right_bracket_bracket => "]]",
                .left_curly_bracket => "{",
                .right_curly_bracket => "}",
                .left_paren => "(",
                .right_paren => ")",
                .comma => ",",
                .colon => ":",
                .dot => ".",
                .semicolon => ";",
                .equal => "",
                .plus => "+",
                .minus => "-",
                .minus_minus => "--",
                .asterisk => "*",
                .slash => "/",
                .caret => "^",
                .percent => "%",
                .dot_dot => "..",
                .dot_dot_dot => "...",
                .left_angle_bracket => "<",
                .left_angle_bracket_equal => "<=",
                .right_angle_bracket => ">",
                .right_angle_bracket_equal => ">=",
                .equal_equal => "==",
                .tilde_equal => "~=",
                .octothorpe => "#",
                .keyword_and => "and",
                .keyword_break => "break",
                .keyword_do => "do",
                .keyword_else => "else",
                .keyword_elseif => "elseif",
                .keyword_end => "end",
                .keyword_false => "false",
                .keyword_for => "for",
                .keyword_function => "function",
                .keyword_if => "if",
                .keyword_in => "in",
                .keyword_local => "local",
                .keyword_nil => "nil",
                .keyword_not => "not",
                .keyword_or => "or",
                .keyword_repeat => "repeat",
                .keyword_return => "return",
                .keyword_then => "then",
                .keyword_true => "true",
                .keyword_until => "until",
                .keyword_while => "while",
            }
        }

        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .invalid => "invalid token",
                .identifier => "an identifier",
                .string_literal => "a string literal",
                .eof => "EOF",
                .number_literal => "a number literal",
                else => unreachable,
            };
        }
    };
};

pub const Lexer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub fn init(buffer: [:0]const u8) Lexer {
        // Skip the UTF-8 BOM if present.
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    const State = enum {
        start,
        identifier,
        invalid,
        string_literal_single,
        string_literal_double,
        number,
        number_dot,
        number_exponent,
        left_bracket,
        // right_bracket,
        left_angle_bracket,
        right_angle_bracket,
        dot,
        minus,
        equal,
        tilde,
        long_bracket,
        line_comment,
    };

    pub fn next(self: *Lexer) Token {
        var result: Token = .{ .tag = undefined, .loc = .{
            .start = self.index,
            .end = undefined,
        } };

        state: switch (State.start) {
            .start => switch (self.buffer[self.index]) {
                0 => {
                    if (self.index == self.buffer.len) {
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    } else {
                        continue :state .invalid;
                    }
                },
                ' ', '\t', '\n' => {
                    self.index += 1;
                    result.loc.start = self.index;

                    continue :state .start;
                },
                '"' => {
                    result.tag = .string_literal;
                    continue :state .string_literal_double;
                },
                '\'' => {
                    result.tag = .string_literal;
                    continue :state .string_literal_single;
                },
                'a'...'z', 'A'...'Z', '_' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '0'...'9' => {
                    result.tag = .number_literal;
                    continue :state .number;
                },
                '.' => continue :state .dot,
                '-' => continue :state .minus,
                '[' => continue :state .left_bracket,
                // ']' => continue :state .right_bracket,
                '<' => continue :state .left_angle_bracket,
                '>' => continue :state .right_angle_bracket,
                '=' => continue :state .equal,
                '~' => continue :state .tilde,
                '(' => {
                    result.tag = .left_paren;
                    self.index += 1;
                },
                '{' => {
                    result.tag = .left_curly_bracket;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .right_paren;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .right_curly_bracket;
                    self.index += 1;
                },
                ',' => {
                    result.tag = .comma;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                ':' => {
                    result.tag = .colon;
                    self.index += 1;
                },
                '+' => {
                    result.tag = .plus;
                    self.index += 1;
                },
                '*' => {
                    result.tag = .asterisk;
                    self.index += 1;
                },
                '/' => {
                    result.tag = .slash;
                    self.index += 1;
                },
                '^' => {
                    result.tag = .caret;
                    self.index += 1;
                },
                '%' => {
                    result.tag = .percent;
                    self.index += 1;
                },
                '#' => {
                    result.tag = .octothorpe;
                    self.index += 1;
                },
                else => continue :state .invalid,
            },

            //string literal

            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
                    else => {
                        const ident = self.buffer[result.loc.start..self.index];
                        if (Token.getKeyword(ident)) |tag| {
                            result.tag = tag;
                        }
                    },
                }
            },

            .dot => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '.' => continue :state .dot,
                    else => {
                        switch (self.index - result.loc.start) {
                            1 => result.tag = .dot,
                            2 => result.tag = .dot_dot,
                            else => {
                                result.tag = .dot_dot_dot;
                                self.index = result.loc.start + 3;
                            },
                        }
                    },
                }
            },
            .minus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '-' => continue :state .line_comment,
                    else => result.tag = .minus,
                }
            },
            .line_comment => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .invalid;
                        } else return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    },
                    // '\r' case for windows
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        // ignore comment
                        continue :state .start;
                    },
                    0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
                        continue :state .invalid;
                    },
                    else => continue :state .line_comment,
                }
            },
            .left_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '[' => continue :state .long_bracket,
                    else => result.tag = .left_bracket,
                }
            },
            .left_angle_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .left_angle_bracket_equal;
                    },
                    else => result.tag = .left_angle_bracket,
                }
            },

            .right_angle_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .right_angle_bracket_equal;
                    },
                    else => result.tag = .right_angle_bracket,
                }
            },

            .equal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .equal_equal;
                    },
                    else => result.tag = .equal,
                }
            },
            .tilde => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .tilde_equal;
                    },
                    else => result.tag = .invalid,
                }
            },
            .number => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9',
                    'a'...'d',
                    'f',
                    'x',
                    'A'...'D',
                    'F',
                    => continue :state .number,
                    '.' => continue :state .number_dot,
                    'e', 'E' => {
                        self.index += 1;
                        switch (self.buffer[self.index]) {
                            '+', '-' => self.index += 1,
                            else => {},
                        }
                        continue :state .number_exponent;
                    },
                    else => {},
                }
            },
            .number_dot => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9',
                    'a'...'d',
                    'f',
                    'x',
                    'A'...'D',
                    'F',
                    => continue :state .number,
                    'e', 'E' => continue :state .number_exponent,
                    else => self.index -= 1,
                }
            },
            .number_exponent => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9',
                    'a'...'f',
                    'A'...'F',
                    '+',
                    '-',
                    => continue :state .number,
                    else => {},
                }
            },
            .string_literal_single => {},
            .string_literal_double => {},
            .long_bracket => {},
            .invalid => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else {
                        continue :state .invalid;
                    },
                    '\n' => result.tag = .invalid,
                    else => continue :state .invalid,
                }
            },
        }

        result.loc.end = self.index;
        return result;
    }
};

fn testLex(src: [:0]const u8, expected_tags: []const Token.Tag) !void {
    var lexer = Lexer.init(src);
    for (expected_tags) |expected| {
        const actual = lexer.next();
        try std.testing.expectEqual(expected, actual.tag);
    }

    const last_token = lexer.next();
    try std.testing.expectEqual(Token.Tag.eof, last_token.tag);
}

test "keyword tokens" {
    try testLex("and", &.{Token.Tag.keyword_and});
    try testLex("break", &.{Token.Tag.keyword_break});
    try testLex("do", &.{Token.Tag.keyword_do});
    try testLex("else", &.{Token.Tag.keyword_else});
    try testLex("elseif", &.{Token.Tag.keyword_elseif});
    try testLex("end", &.{Token.Tag.keyword_end});
    try testLex("false", &.{Token.Tag.keyword_false});
    try testLex("for", &.{Token.Tag.keyword_for});
    try testLex("function", &.{Token.Tag.keyword_function});
    try testLex("if", &.{Token.Tag.keyword_if});
    try testLex("in", &.{Token.Tag.keyword_in});
    try testLex("local", &.{Token.Tag.keyword_local});
    try testLex("nil", &.{Token.Tag.keyword_nil});
    try testLex("not", &.{Token.Tag.keyword_not});
    try testLex("or", &.{Token.Tag.keyword_or});
    try testLex("repeat", &.{Token.Tag.keyword_repeat});
    try testLex("return", &.{Token.Tag.keyword_return});
    try testLex("then", &.{Token.Tag.keyword_then});
    try testLex("true", &.{Token.Tag.keyword_true});
    try testLex("until", &.{Token.Tag.keyword_until});
    try testLex("while", &.{Token.Tag.keyword_while});
}

test "number literals" {
    try testLex("3", &.{Token.Tag.number_literal});
    try testLex("3.0", &.{Token.Tag.number_literal});
    try testLex("3.1416", &.{Token.Tag.number_literal});
    try testLex("0xff", &.{Token.Tag.number_literal});
    try testLex("0x56", &.{Token.Tag.number_literal});
    try testLex("0x1.adef", &.{Token.Tag.number_literal});
}

test "number exponent literals" {
    try testLex("314.16e-2", &.{Token.Tag.number_literal});
    try testLex("0.31416E1", &.{Token.Tag.number_literal});
    try testLex("0x1.abcedfe10", &.{Token.Tag.number_literal});
    try testLex("0x1.abcedfE10", &.{Token.Tag.number_literal});
}
