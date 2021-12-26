const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;
const int = i64;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day24.txt");

const Emulator = struct {
    const div = [_]bool{
        false,
            false,
                false,
                    false,
                        false,
                        true,
                        false,
                        true,
                    true,
                    false,
                    true,
                true,
            true,
        true,
    };
    const add1 = [_]int{
        12, 11, 13, 11, 14, -10, 11,
        -9, -3, 13, -5, -10, -4, -5,
    };
    const add2 = [_]int{
        4, 11, 5, 11, 14, 7, 11,
        4, 6, 5, 9, 12, 14, 14,
    };

    pub fn emulate(input: []const u8) bool {
        var z: int = 0;
        var i: usize = 0;
        while (i < 14) : (i += 1) {
            const w = input[i];
            print("\ninput {}: {}\n", .{i, w});
            const rz = @rem(z, 26);
            const x = rz + add1[i];
            print("x = {} ({} + {})\n", .{x, rz, add1[i]});
            if (div[i]) {
                z = @divTrunc(z, 26);
                print("pop\n", .{});
            }
            if (x != w) {
                z *= 26;
                const new_val = add2[i] + w;
                z += new_val;
                print("push\n", .{});
            }
            print("z =", .{});
            var zz = z;
            while (zz != 0) {
                print(" {}", .{@mod(zz, 26)});
                zz = @divTrunc(zz, 26);
            }
            print("\n", .{});
        }
        return z == 0;
    }
};

const PendingDigit = struct {
    index: u8,
    add2: i8,
};

pub fn main() !void {
    var max_val: [14]u8 = undefined;
    var min_val: [14]u8 = undefined;

    var lines = tokenize(u8, data, "\r\n");
    var input_idx: u8 = 0;
    var stack = std.BoundedArray(PendingDigit, 7).init(0) catch unreachable;
    while (lines.next()) |line| : (input_idx += 1) {
        assert(eql(u8, line, "inp w"));
        assert(eql(u8, lines.next().?, "mul x 0"));
        assert(eql(u8, lines.next().?, "add x z"));
        assert(eql(u8, lines.next().?, "mod x 26"));
        const pop_line = lines.next().?;
        const pop = pop_line.len == 8;
        if (pop) {
            assert(eql(u8, pop_line, "div z 26"));
        } else {
            assert(eql(u8, pop_line, "div z 1"));
        }
        const add1_line = lines.next().?;
        assert(eql(u8, add1_line[0..6], "add x "));
        const add1 = try parseInt(i8, add1_line[6..], 10);
        assert(eql(u8, lines.next().?, "eql x w"));
        assert(eql(u8, lines.next().?, "eql x 0"));
        assert(eql(u8, lines.next().?, "mul y 0"));
        assert(eql(u8, lines.next().?, "add y 25"));
        assert(eql(u8, lines.next().?, "mul y x"));
        assert(eql(u8, lines.next().?, "add y 1"));
        assert(eql(u8, lines.next().?, "mul z y"));
        assert(eql(u8, lines.next().?, "mul y 0"));
        assert(eql(u8, lines.next().?, "add y w"));
        const add2_line = lines.next().?;
        assert(eql(u8, add2_line[0..6], "add y "));
        const add2 = try parseInt(i8, add2_line[6..], 10);
        assert(eql(u8, lines.next().?, "mul y x"));
        assert(eql(u8, lines.next().?, "add z y"));

        if (!pop) {
            assert(add1 > 9);
            stack.appendAssumeCapacity(.{
                .index = input_idx,
                .add2 = add2,
            });
        } else {
            assert(add1 < 0);
            const pair = stack.pop();
            // a + add2 + add1 == b
            // a - b == add1 + add2
            const diff = add1 + pair.add2;
            assert(diff > -9 and diff < 9);
            if (diff > 0) {
                const diff_u8 = @intCast(u8, diff);
                max_val[pair.index] = '9' - diff_u8;
                max_val[input_idx] = '9';
                min_val[pair.index] = '1';
                min_val[input_idx] = '1' + diff_u8;
            } else {
                const diff_u8 = @intCast(u8, -diff);
                max_val[pair.index] = '9';
                max_val[input_idx] = '9' - diff_u8;
                min_val[pair.index] = '1' + diff_u8;
                min_val[input_idx] = '1';
            }
        }
    }

    print("part1={s}, part2={s}\n", .{&max_val, &min_val});
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

const parseEnum = std.meta.stringToEnum;

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
