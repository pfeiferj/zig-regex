const Reader = @import("./reader.zig").Reader;

pub fn Range(comptime reader: *Reader) type {
    comptime var first_char = reader.data[reader.index];
    comptime var final_char = reader.data[reader.index + 2];
    reader.index += 3;

    comptime var T = struct {
        first_char: u8,
        final_char: u8,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .first_char = first_char,
                .final_char = final_char,
            };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            const c = r.data[r.index];
            r.index += 1;

            if (c < self.first_char) {
                return false;
            }
            if (c > self.final_char) {
                return false;
            }

            return true;
        }
    };

    return T;
}
