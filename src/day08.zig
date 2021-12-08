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

fn segmentMask(str: []const u8) u7 {
    var set = std.StaticBitSet(7).initEmpty();
    for (str) |chr| {
        set.set(chr - 'a');
    }
    return set.mask;
}

pub fn main() !void {
    var part1: int = 0;
    var part2: int = 0;

    var lines = tokenize(u8, data, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) { continue; }
        var parts = tokenize(u8, line, " |");

        var four: u7 = undefined;
        var seven: u7 = undefined;
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            const str = parts.next().?;
            if (str.len == 4) four = segmentMask(str);
            if (str.len == 3) seven = segmentMask(str);
        }

        i = 0;
        var num: int = 0;
        while (i < 4) : (i += 1) {
            const str = parts.next().?;
            const digit: int = switch (str.len) {
                2 => blk: { part1 += 1; break :blk @as(int, 1); },
                3 => blk: { part1 += 1; break :blk @as(int, 7); },
                4 => blk: { part1 += 1; break :blk @as(int, 4); },
                7 => blk: { part1 += 1; break :blk @as(int, 8); },
                5 => blk: {
                    const mask = segmentMask(str);
                    break :blk if (mask & seven == seven) @as(int, 3)
                    else if (@popCount(u7, mask & four) == 3) @as(int, 5)
                    else @as(int, 2);
                },
                6 => blk: {
                    const mask = segmentMask(str);
                    break :blk if (mask & four == four) @as(int, 9)
                    else if (mask & seven == seven) @as(int, 0)
                    else @as(int, 6);
                },
                else => unreachable,
            };
            num = num * 10 + digit;
        }
        part2 += @intCast(int, num);

        assert(parts.next() == null);
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
