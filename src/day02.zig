const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day02.txt");

const Direction = enum {
    forward,
    down,
    up,
};

pub fn main() !void {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var aim: i64 = 0;
    var horz: i64 = 0;
    var vert: i64 = 0;

    var lines = tokenize(u8, data, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = split(u8, line, " ");
        const dir_str = parts.next().?;
        const dist_str = parts.next().?;
        assert(parts.next() == null);

        const dist = parseInt(i64, dist_str, 10) catch unreachable;

        switch (strToEnum(Direction, dir_str).?) {
            .forward => {
                horz += dist;
                vert += dist * aim;
            },
            .up => aim -= dist,
            .down => aim += dist,
        }
    }

    part1 = horz * aim;
    part2 = horz * vert;

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
const strEql = std.mem.eql;

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
