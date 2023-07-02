const std = @import("std");
const Reader = @import("./reader.zig").Reader;
const Suffix = @import("./suffix.zig").Suffix;
const CharacterSet = @import("./character_set.zig").CharacterSet;
const Literal = @import("./literal.zig").Literal;
const Group = @import("./group.zig").Group;
const LastCharacter = @import("./last_character.zig").LastCharacter;

pub fn compile(comptime rex: []const u8) type {
    comptime var reader = Reader{ .data = rex, .index = 0 };
    return _compile(&reader);
}

pub fn _compile(comptime reader: *Reader) type {
    comptime var char = reader.data[reader.index];
    comptime var check_beginning = false;
    if (char == '^' and reader.index == 0) {
        check_beginning = true;
        reader.index += 1;
        char = reader.data[reader.index];
    }
    comptime var token = blk: {
        // handle escaped characters
        if (char == '\\') {
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
        }
        break :blk switch (char) {
            '(' => Group(reader),
            '[' => CharacterSet(reader),
            '$' => LastCharacter(reader),
            '.' => block: {
                reader.index += 1;
                comptime var character_reader = Reader{ .data = "[^\r\n]", .index = 0 };
                break :block CharacterSet(&character_reader);
            },
            else => Literal(reader),
        };
    };

    comptime var tokens = switch (reader.data.len - reader.index) {
        0 => .{token.init()},
        else => .{token.init()} ++ _compile(reader).init().tokens,
    };

    return comptime struct {
        tokens: @TypeOf(tokens),
        check_beginning: bool = check_beginning,

        const Self = @This();
        pub fn init() Self {
            return Self{
                .tokens = tokens,
                .check_beginning = check_beginning,
            };
        }

        pub fn print(self: @This()) void {
            inline for (self.tokens) |t| {
                t.print();
            }
        }

        pub fn matches(self: @This(), input: []const u8) bool {
            var r = Reader{
                .data = input,
                .index = 0,
            };

            return self.reader_matches(&r);
        }

        pub fn reader_matches(self: @This(), r: *Reader) bool {
            if (self.check_beginning and r.index != 0) {
                return false;
            }
            const start_index = r.index;
            var last_loop_index: usize = 0;

            outer: while ((start_index == 0 and last_loop_index < r.data.len and !self.check_beginning) or last_loop_index < 1) : (last_loop_index += 1) {
                r.index = last_loop_index;
                inline for (self.tokens) |t| {
                    if (!t.matches(r)) {
                        continue :outer;
                    }
                }
                return true;
            }
            return false;
        }
    };
}
