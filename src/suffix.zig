const Reader = @import("./reader.zig").Reader;

pub fn Suffix(comptime reader: *Reader, comptime token: type) type {
    if (reader.index >= reader.data.len) {
        return token;
    }

    comptime var char = reader.data[reader.index];

    comptime var T = switch (char) {
        '?' => struct {
            child: @typeInfo(@TypeOf(token.init)).Fn.return_type.?,

            const Self = @This();

            pub fn init() Self {
                return Self{ .child = token.init() };
            }

            pub fn matches(self: @This(), r: *Reader) bool {
                const initial_index = r.index;
                const m = self.child.matches(r);
                if (!m) {
                    r.index = initial_index;
                }
                return true;
            }
        },
        '*' => struct {
            child: @typeInfo(@TypeOf(token.init)).Fn.return_type.?,

            const Self = @This();

            pub fn init() Self {
                return Self{ .child = token.init() };
            }

            pub fn matches(self: @This(), r: *Reader) bool {
                while (r.index < r.data.len) {
                    const initial_index = r.index;
                    const m = self.child.matches(r);
                    if (!m) {
                        r.index = initial_index;
                        break;
                    }
                }
                return true;
            }
        },
        '+' => struct {
            child: @typeInfo(@TypeOf(token.init)).Fn.return_type.?,

            const Self = @This();

            pub fn init() Self {
                return Self{ .child = token.init() };
            }

            pub fn matches(self: @This(), r: *Reader) bool {
                const initial_index = r.index;

                while (r.index < r.data.len) {
                    const iteration_initial_index = r.index;
                    const m = self.child.matches(r);
                    if (!m) {
                        r.index = iteration_initial_index;
                        break;
                    }
                }

                if (r.index == initial_index) {
                    return false;
                }

                return true;
            }
        },
        else => token,
    };

    if (T != token) {
        reader.index += 1;
    }

    return T;
}
