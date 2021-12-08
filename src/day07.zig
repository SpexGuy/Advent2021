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

const data = @embedFile("../data/day07.txt");

const Record = struct {
    pos: int,
};

pub fn main() !void {
    var total: int = 0;
    const positions = blk: {
        var recs = List(int).init(gpa);
        var iter = tokenize(u8, data, "\r\n,");
        while (iter.next()) |num| {
            if (num.len == 0) { continue; }

            const dist = try parseInt(int, num, 10);
            total += dist;
            try recs.append(dist);
        }
        break :blk recs.toOwnedSlice();
    };

    // The ideal part 1 position is the median, so sort and then
    // grab the middle value.  If there are an even number of positions,
    // then any value between the two median values is a minimum.
    // In order for AoC to have a unique answer, we can assume that
    // either the number of positions is odd, or the two medians
    // have the same value.
    sort(int, positions, {}, comptime asc(int));
    const part1_pos = positions[positions.len / 2];
    var part1: int = 0;
    for (positions) |rec| {
        part1 += std.math.absInt(rec - part1_pos) catch unreachable;
    }

    // The ideal part 2 position is the average location, but that is probably
    // not an integer.  The cost curve is not symmetric, so rounding to the
    // nearest integer may not be correct.  But the best integer value must
    // be either the floor or ciel of the real average value, so we will
    // calculate and test both.
    const avg_min = @divTrunc(total, @intCast(int, positions.len));
    const avg_max = @divTrunc(total + @intCast(int, positions.len) - 1, @intCast(int, positions.len));
    var low_cost: int = 0;
    var high_cost: int = 0;
    for (positions) |it| {
        const low_diff = std.math.absInt(it - avg_min) catch unreachable;
        low_cost += @divExact(low_diff * (low_diff + 1), 2);
        const high_diff = std.math.absInt(it - avg_max) catch unreachable;
        high_cost += @divExact(high_diff * (high_diff + 1), 2);
    }
    const part2 = min(low_cost, high_cost);

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
