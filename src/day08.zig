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

const data = @embedFile("../data/day08.txt");

fn numFromStr(str: []const u8) u7 {
    var set = std.StaticBitSet(7).initEmpty();
    for (str) |chr| {
        set.set(chr - 'a');
    }
    return set.mask;
}

const Input = struct {
    in: [10]u7,
    out: [4]u7,

    fn findDigit(self: @This(), num: u7) usize {
        switch (@popCount(u7, num)) {
            2 => return 1,
            3 => return 7,
            4 => return 4,
            7 => return 8,
            5 => {
                const seven = self.in[1];
                const four = self.in[2];
                if (num & seven == seven) {
                    return 3;
                } else if (@popCount(u7, num & four) == 3) {
                    return 5;
                } else {
                    return 2;
                }
            },
            6 => {
                const seven = self.in[1];
                const four = self.in[2];
                if (num & four == four) {
                    return 9;
                } else if (num & seven == seven) {
                    return 0;
                } else {
                    return 6;
                }
            },
            else => unreachable,
        }
    }
};

fn ascCount(_: void, a: u7, b: u7) bool {
    return @popCount(u7, a) < @popCount(u7, b);
}

pub fn main() !void {
    var part1: int = 0;
    var part2: int = 0;

    var lines = tokenize(u8, data, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) { continue; }
        var parts = tokenize(u8, line, " |");

        var input: Input = undefined;
        for (input.in) |*it| {
            it.* = numFromStr(parts.next().?);
        }
        for (input.out) |*it| {
            it.* = numFromStr(parts.next().?);
        }
        assert(parts.next() == null);

        sort(u7, &input.in, {}, ascCount);

        for (input.out) |out| {
            switch (@popCount(u7, out)) {
                2, 3, 4, 7 => part1 += 1,
                5, 6 => {},
                else => unreachable,
            }
        }

        const d3 = input.findDigit(input.out[0]);
        const d2 = input.findDigit(input.out[1]);
        const d1 = input.findDigit(input.out[2]);
        const d0 = input.findDigit(input.out[3]);
        const num = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
        part2 += @intCast(int, num);
    }

    print("part1={}, part2={}\n", .{part1, part2});
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
