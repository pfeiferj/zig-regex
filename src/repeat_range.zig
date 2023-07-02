const std = @import("std");
const Reader = @import("./reader.zig").Reader;

pub fn RepeatRange(comptime reader: *Reader, comptime child: type) type {
    reader.index += 1;
    comptime var min: usize = 0;
    comptime var initial_index = reader.index;
    while (reader.data[reader.index] != ',') {
        reader.index += 1;
    }
    if (reader.index != initial_index) {
        min = std.fmt.parseInt(usize, reader.data[initial_index..reader.index], 10) catch {
            unreachable;
        };
    }
    reader.index += 1;
    comptime var max: usize = std.math.maxInt(usize);
    initial_index = reader.index;
    while (reader.data[reader.index] != '}') {
        reader.index += 1;
    }
    if (reader.index != initial_index) {
        max = std.fmt.parseInt(usize, reader.data[initial_index..reader.index], 10) catch {
            unreachable;
        };
    }

    return comptime struct {
        min: usize,
        max: usize,
        child: @typeInfo(@TypeOf(child.init)).Fn.return_type.?,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .min = min,
                .max = max,
                .child = child.init(),
            };
        }

        pub fn matches(self: @This(), r: *Reader) bool {
            var match_count: usize = 0;

            while (r.index < r.data.len) {
                const iteration_initial_index = r.index;
                const m = self.child.matches(r);
                if (!m) {
                    r.index = iteration_initial_index;
                    break;
                }
                match_count += 1;
                if (match_count >= self.max) {
                    break;
                }
            }

            if (match_count < self.min) {
                return false;
            }

            return true;
        }
    };
}
