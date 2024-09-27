const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "do", .keyword_do },
        .{ "end", .keyword_end },
        .{ "while", .keyword_while },
        .{ "until", .keyword_until },
        .{ "if", .keyword_if },
        .{ "then", .keyword_then },
        .{ "elseif", .keyword_elseif },
        .{ "else", .keyword_else },
        .{ "for", .keyword_for },
        .{ "function", .keyword_function },
        .{ "local", .keyword_local },
        .{ "return", .keyword_return },
        .{ "break", .keyword_break },
        .{ "and", .keyword_and },
        .{ "or", .keyword_or },
        .{ "not", .keyword_not },
        .{ "true", .keyword_true },
        .{ "false", .keyword_false },
        .{ "nil", .keyword_nil },
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
        number_literal,
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
                    continue :state .number_literal;
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

            // number

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
            .number_literal => {},
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
