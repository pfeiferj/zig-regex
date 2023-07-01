const Reader = @import("./reader.zig").Reader;
const Suffix = @import("./suffix.zig").Suffix;

pub fn Literal(comptime reader: *Reader) type {
    comptime var char = reader.data[reader.index];
    comptime var T = struct {
        char: u8,

        const Self = @This();
        pub fn init() Self {
            return Self{
                .char = char,
            };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            if (r.index >= r.data.len) {
                return false;
            }
            const c = r.data[r.index];
            r.index += 1;

            if (c == self.char) {
                return true;
            }

            return false;
        }
    };

    reader.index += 1;

    return Suffix(reader, T);
}
