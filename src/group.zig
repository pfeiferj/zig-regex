const std = @import("std");
const Reader = @import("./reader.zig").Reader;
const Suffix = @import("./suffix.zig").Suffix;
const compile_reader = @import("./compile.zig").compile_reader;

//TODO might be better to make everything deal with reader_matches
pub fn Group(comptime reader: *Reader) type {
    reader.index += 1;
    comptime var initial_index = reader.index;

    var depth: usize = 1;

    while (depth > 0 and reader.index < reader.data.len) {
        comptime var char = reader.data[reader.index];
        reader.index += 1;

        if (char == '(') {
            depth += 1;
        } else if (char == '\\') { // skip next char if escaped
            reader.index += 1;
        } else if (char == ')') {
            depth -= 1;
        }
    }
    comptime var child_reader = Reader{
        .data = reader.data[initial_index..(reader.index - 1)],
        .index = 0,
    };

    comptime var child_rex = compile_reader(&child_reader);

    comptime var T = struct {
        child: child_rex,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .child = child_rex.init(),
            };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            return self.child.reader_matches(r);
        }
    };
    return Suffix(reader, T);
}
