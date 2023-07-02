# Zig Regex
A regex engine for zig that compiles an expression at comptime and requires 0 dynamic allocation at runtime.

## WIP
### Is it well tested?
No.

### Is it fast?
Maybe? Haven't checked, probably not though. Other than taking advantage of comptime to allow for 0 dynamic allocation at runtime the implementation doesn't really do anything clever.

### Usage

```zig
const compile = @import("regex").compile;

const expression = "abc$"; // Must be known at comptime

pub fn main() !void {
    comptime var rex = compile(expression).init();
    const m = rex.matches("1234abc");
    std.debug.print("matches: {}\n", .{m}); // Prints: `true`
}
```

### Supported Syntax

* Literals (match a single character)
* Character Sets
    - `[abc]` - 'a' or 'b' or 'c'
    - `[^abc]` - not any of 'a' or 'b' or 'c'
    - `[a-zA-Z]` - any character from a through (inclusive) z or A through Z

* Groups
    - `(abcd)+` - Matches the string `abcd` 1 or more times

* Suffixes:
    - `?` - preceding rule is optional (literal, character set, group)
    - `*` - preceding rule is repeated 0 or more times (literal, character set, group, etc.)
    - `+` - preceding rule is repeated 1 or more times (literal, character set, group, etc.)

* Special Characters
    - `.` - non line break character ([^\r\n])
    - `^` - matches the start of the input
    - `$` - matches the end of the input

* Escape Sequences
    - `\w` - word ([A-Za-z0-9_])
    - `\W` - not word ([^A-Za-z0-9_])
    - `\d` - digit ([0-9])
    - `\D` - not digit ([^0-9])
    - `\s` - whitespace (spaces, tabs, line breaks)

* Escaped Literals
    - `\0` - null
    - `\r` - carriage return
    - `\f` - form feed
    - `\v` - vertical tab
    - `\n` - line feed
    - `\t` - tab
    - `+*?^$\.[]{}()|/` - must be escaped for literal
    - `\-]` - need to be escaped for literal in character set

* Repeat Ranges
    - `{1,3}` - matches the preceding rule 1 through 3 times inclusive.
    - `{,3}` - matches the preceding rule 0 through 3 times inclusive.
    - `{1,}` - matches the preceding rule 1 or more times (up to max usize).

### Not Yet Implemented
* `|` - Match the rule before or after
* escaped parenthesis in a group
