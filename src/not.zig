const Reader = @import("./reader.zig").Reader;

pub fn Not(comptime token: type) type {
    return struct {
        child: @typeInfo(@TypeOf(token.init)).Fn.return_type.?,

        const Self = @This();

        pub fn init() Self {
            return Self{ .child = token.init() };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            return !self.child.matches(r);
        }
    };
}
