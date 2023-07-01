const Reader = @import("./reader.zig").Reader;
const Suffix = @import("./suffix.zig").Suffix;

pub fn LastCharacter(comptime reader: *Reader) type {
    comptime var T = struct {
        const Self = @This();
        pub fn init() Self {
            return Self{};
        }

        pub fn matches(_: @This(), r: *Reader) bool {
            if (r.index == r.data.len) {
                return true;
            }
            return false;
        }
    };

    reader.index += 1;

    return T;
}
