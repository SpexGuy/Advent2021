const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

pub var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here
pub const default_delims = " ,:(){}<>[]!\r\n\t";

pub fn parseLines(comptime T: type, text: []const u8) []T {
    return parseLinesDelim(T, text, default_delims);
}

pub fn parseLinesDelim(comptime T: type, text: []const u8, delims: []const u8) []T {
    var list = List(T).init(gpa);
    var lines = tokenize(u8, text, "\r\n");
    var linenum: u32 = 1;
    while (lines.next()) |line| : (linenum += 1) {
        if (line.len == 0) { continue; }
        list.append(parseLine(T, line, delims, linenum)) catch unreachable;
    }
    return list.toOwnedSlice();
}

pub fn parse(comptime T: type, str: []const u8) T {
    return parseLine(T, str, default_delims, 1337);
}

pub fn parseLine(comptime T: type, str: []const u8, delims: []const u8, linenum: u32) T {
    var it = std.mem.tokenize(u8, str, delims);
    const result = parseNext(T, &it, linenum).?;
    if (it.next()) |next| {
        debugError("Extra token on line {}: '{s}'", .{linenum, next});
    }
    return result;
}

pub fn parseNext(comptime T: type, it: *std.mem.TokenIterator(u8), linenum: u32) ?T {
    if (T == []const u8) return it.next();
    switch (@typeInfo(T)) {
        .Int => {
            const token = it.next() orelse return null;
            return parseInt(T, token, 10)
                catch |err| debugError("invalid integer '{s}' on line {}, err={}", .{token, linenum, err});
        },
        .Float => {
            const token = it.next() orelse return null;
            return parseFloat(T, token)
                catch |err| debugError("invalid float '{s}' on line {}, err={}", .{token, linenum, err});
        },
        .Enum => {
            const token = it.next() orelse return null;
            return strToEnum(T, token)
                orelse debugError("cannot convert '{s}' to enum {s} on line {}", .{token, @typeName(T), linenum});
        },
        .Array => |arr| {
            var result: T = undefined;
            for (result) |*item, i| {
                item.* = parseNext(arr.child, it, linenum) orelse {
                    if (i == 0) { return null; }
                    debugError("Only found {} of {} items in array, on line {}\n", .{i, arr.len, linenum});
                };
            }
            return result;
        },
        .Struct => |str| {
            var result: T = undefined;
            _ = str;
            var exit: bool = false; // workaround for control flow in inline for issues
            inline for (str.fields) |field, i| {
                parseNextStructField(&result, field, i, &exit, it, linenum);
            }
            if (exit) return null;
            return result;
        },
        .Optional => |opt| {
            return @as(T, parseNext(opt.child, it, linenum));
        },
        .Pointer => |ptr| {
            if (ptr.size == .Slice) {
                var results = List(ptr.child).init(gpa);
                while (parseNext(ptr.child, it, linenum)) |value| {
                    results.append(value) catch unreachable;
                }
                return results.toOwnedSlice();
            } else @compileError("Unsupported type "++@typeName(T));
        },
        else => @compileError("Unsupported type "++@typeName(T)),
    }
}

fn parseNextStructField(
    result: anytype,
    comptime field: std.builtin.TypeInfo.StructField,
    comptime i: usize,
    exit: *bool,
    it: *std.mem.TokenIterator(u8),
    linenum: u32,
) void {
    if (!exit.*) {
        if (field.name[0] == '_') {
            @field(result, field.name) = field.default_value orelse undefined;
        } else if (parseNext(field.field_type, it, linenum)) |value| {
            @field(result, field.name) = value;
        } else if (field.default_value) |default| {
            @field(result, field.name) = default;
        } else if (i == 0) {
            exit.* = true;
        } else if (comptime std.meta.trait.isSlice(field.field_type)) {
            @field(result, field.name) = &.{};
        } else {
            debugError("Missing field {s}.{s} and no default, on line {}", .{@typeName(@TypeOf(result)), field.name, linenum});
        }
    }
}

test "parseLine" {
    assert(parseLine(u32, " 42 ", " ,", @src().line) == 42);
    assert(parseLine(f32, " 0.5", " ,", @src().line) == 0.5);
    assert(parseLine(f32, "42", " ,", @src().line) == 42);
    assert(parseLine(enum { foo, bar }, "foo", " ,", @src().line) == .foo);
    assert(eql(u16, &parseLine([3]u16, " 2, 15 4 ", " ,", @src().line), &[_]u16{2, 15, 4}));
    assert(eql(u16, parseLine([]u16, " 2, 15 4 ", " ,", @src().line), &[_]u16{2, 15, 4}));
    assert(parseLine(?f32, "42", " ,", @src().line).? == 42);
    assert(parseLine(?f32, "", " ,", @src().line) == null);
    assert(eql(u8, parseLine([]const u8, "foob", " ,", @src().line), "foob"));
    assert(eql(u8, parseLine([]const u8, "foob", " ,", @src().line), "foob"));
    assert(eql(u8, parseLine(Str, "foob", " ,", @src().line), "foob"));

    const T = struct {
        int: i32,
        float: f32,
        enumeration: enum{ foo, bar, baz },
        _first: bool = true,
        array: [3]u16,
        string: []const u8,
        _skip: *@This(),
        optional: ?u16,
        tail: [][]const u8,
    };

    {
        const a = parseLine(T, "4: 5.0, bar 4, 5, 6 badaboom", ":, ", @src().line);
        assert(a.int == 4);
        assert(a.float == 5.0);
        assert(a.enumeration == .bar);
        assert(a._first == true);
        assert(eql(u16, &a.array, &[_]u16{4, 5, 6}));
        assert(eql(u8, a.string, "badaboom"));
        assert(a.optional == null);
        assert(a.tail.len == 0);
    }

    {
        const a = parseLine(T, "-5: 3: foo 4, 5, 6 booptroop 53", ":, ", @src().line);
        assert(a.int == -5);
        assert(a.float == 3);
        assert(a.enumeration == .foo);
        assert(a._first == true);
        assert(eql(u16, &a.array, &[_]u16{4, 5, 6}));
        assert(eql(u8, a.string, "booptroop"));
        assert(a.optional.? == 53);
        assert(a.tail.len == 0);
    }

    {
        const a = parseLine(T, "+15: -10: baz 5, 6, 7 skidoosh 82 ruby supports bare words", ":, ", @src().line);
        assert(a.int == 15);
        assert(a.float == -10);
        assert(a.enumeration == .baz);
        assert(a._first == true);
        assert(eql(u16, &a.array, &[_]u16{5, 6, 7}));
        assert(eql(u8, a.string, "skidoosh"));
        assert(a.optional.? == 82);
        assert(a.tail.len == 4);
        assert(eql(u8, a.tail[0], "ruby"));
        assert(eql(u8, a.tail[1], "supports"));
        assert(eql(u8, a.tail[2], "bare"));
        assert(eql(u8, a.tail[3], "words"));
    }

    print("All tests passed.\n", .{});
}

inline fn debugError(comptime fmt: []const u8, args: anytype) noreturn {
    if (std.debug.runtime_safety) {
        std.debug.panic(fmt, args);
    } else {
        unreachable;
    }
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;
const eql = std.mem.eql;

const strToEnum = std.meta.stringToEnum;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
