const std = @import("std");
const token = @import("tokenizer.zig");

const print = std.debug.print;

pub fn main() !void {

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    //
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    //
    // try bw.flush(); // Don't forget to flush!

    const source: [:0]const u8 =
        \\local M = {}
        \\local a = c + b -- some comment
        \\function M.foo(a, b)
        \\ return a + b
        \\end
    ;

    var lexer = token.Tokenizer.init(source);
    var tok: token.Token = undefined;

    while (true) {
        tok = lexer.next();
        print("{any}\n", .{tok.tag});
        if (tok.tag == .eof) break;
    }

    return;
}
