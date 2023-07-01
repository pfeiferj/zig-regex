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
            break :blk Not(Suffix(reader, _CharacterSet(reader)));
        },
        else => Suffix(reader, _CharacterSet(reader)),
    };
    reader.index += 1;
    return T;
}

fn _CharacterSet(comptime reader: *Reader) type {
    comptime var token = blk: {
        if (reader.index + 2 < reader.data.len and reader.data[reader.index + 1] == '-') {
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
            return false;
        }
    };

    return T;
}
