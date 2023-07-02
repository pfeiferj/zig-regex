const std = @import("std");
const Reader = @import("./reader.zig").Reader;
const Range = @import("./range.zig").Range;
const Suffix = @import("./suffix.zig").Suffix;
const Literal = @import("./literal.zig").Literal;
const Not = @import("./not.zig").Not;

pub fn CharacterSet(comptime reader: *Reader) type {
    reader.index += 1;
    const char = reader.data[reader.index];
    comptime var T = switch (char) {
        '^' => blk: {
            reader.index += 1;
            break :blk Not(_CharacterSet(reader));
        },
        else => _CharacterSet(reader),
    };
    reader.index += 1;
    return Suffix(reader, T);
}

fn _CharacterSet(comptime reader: *Reader) type {
    comptime var token = blk: {
        if (reader.data[reader.index] == '\\') {
            reader.index += 1;
            const escaped_char = reader.data[reader.index];

            switch (escaped_char) {
                'w' => {
                    reader.index += 1;
                    comptime var word_reader = Reader{ .data = "[A-Za-z0-9_]", .index = 0 };
                    break :blk CharacterSet(&word_reader);
                },
                'W' => {
                    reader.index += 1;
                    comptime var not_word_reader = Reader{ .data = "[^A-Za-z0-9_]", .index = 0 };
                    break :blk CharacterSet(&not_word_reader);
                },
                'd' => {
                    reader.index += 1;
                    comptime var digit = Reader{ .data = "[0-9]", .index = 0 };
                    break :blk CharacterSet(&digit);
                },
                'D' => {
                    reader.index += 1;
                    comptime var not_digit = Reader{ .data = "[^0-9]", .index = 0 };
                    break :blk CharacterSet(&not_digit);
                },
                's' => {
                    reader.index += 1;
                    comptime var whitespace = Reader{ .data = "[ \t\r\n]", .index = 0 };
                    break :blk CharacterSet(&whitespace);
                },
                'S' => {
                    reader.index += 1;
                    comptime var whitespace = Reader{ .data = "[^ \t\r\n]", .index = 0 };
                    break :blk CharacterSet(&whitespace);
                },
                'r' => {
                    reader.index += 1;
                    comptime var carriage_return = Reader{ .data = "\r", .index = 0 };
                    break :blk Literal(&carriage_return);
                },
                'n' => {
                    reader.index += 1;
                    comptime var line_feed = Reader{ .data = "\n", .index = 0 };
                    break :blk Literal(&line_feed);
                },
                't' => {
                    reader.index += 1;
                    comptime var tab = Reader{ .data = "\t", .index = 0 };
                    break :blk Literal(&tab);
                },
                '0' => {
                    reader.index += 1;
                    comptime var nil = Reader{ .data = .{0}, .index = 0 };
                    break :blk Literal(&nil);
                },
                'f' => {
                    reader.index += 1;
                    comptime var form_feed = Reader{ .data = .{12}, .index = 0 };
                    break :blk Literal(&form_feed);
                },
                'v' => {
                    reader.index += 1;
                    comptime var vertical_tab = Reader{ .data = .{11}, .index = 0 };
                    break :blk Literal(&vertical_tab);
                },
                else => {
                    break :blk Literal(reader);
                },
            }
        } else if (reader.index + 2 < reader.data.len and reader.data[reader.index + 1] == '-') {
            break :blk Range(reader);
        } else {
            break :blk Literal(reader);
        }
    };

    comptime var tokens = switch (reader.data[reader.index]) {
        ']' => .{token.init()},
        else => .{token.init()} ++ _CharacterSet(reader).init().tokens,
    };

    comptime var T = struct {
        tokens: @TypeOf(tokens),

        const Self = @This();
        pub fn init() Self {
            return Self{
                .tokens = tokens,
            };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            inline for (self.tokens) |t| {
                if (t.matches(r)) {
                    return true;
                }
                // each token consumes one character, move back a character if no match

                r.index -= 1;
            }
            r.index += 1;
            return false;
        }
    };

    return T;
}
