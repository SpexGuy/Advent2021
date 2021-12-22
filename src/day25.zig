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

const data = @embedFile("../data/day00.txt");

const Rec = struct {
    val: int,
};

pub fn main() !void {
    var part1: int = 0;
    var part2: int = 0;

    var recs = blk: {
        var recs = List(Rec).init(gpa);
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            var parts = split(u8, line, " ");
            const dist_str = parts.next().?;
            assert(parts.next() == null);

            const dist = parseInt(int, dist_str, 10) catch unreachable;

            _ = dist;
            try recs.append(.{
                .val = dist,
            });
        }
        break :blk recs.toOwnedSlice();
    };
    _ = recs;

    //const items = util.parseLinesDelim(Rec, data, " ,:(){}<>[]!\r\n\t");
    //_ = items;

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
