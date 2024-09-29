const std = @import("std");
const lex = @import("lexer.zig");

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
        \\"123
        \\"
    ;

    var lexer = lex.Lexer.init(source);
    var tok: lex.Token = undefined;

    while (true) {
        tok = lexer.next();
        print("{s} {s}\n", .{@tagName(tok.tag), lexer.buffer[tok.loc.start..tok.loc.end]});
        if (tok.tag == .eof) break;
    }

    return;
}
