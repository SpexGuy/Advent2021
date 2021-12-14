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

const data = @embedFile("../data/day14.txt");

const Key = struct {
    pair: [2]u8,
    depth: u8,
};
const Result = std.meta.Vector(26, u64);
const Memo = Map(Key, Result);

const Rules = Map([2]u8, u8);

pub fn main() !void {
    var template: []const u8 = undefined;
    var rules = Rules.init(gpa);
    {
        var lines = tokenize(u8, data, "\r\n");
        template = lines.next().?;
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            var parts = tokenize(u8, line, " -> ");
            const key = parts.next().?;
            const val = parts.next().?;
            assert(parts.next() == null);
            assert(key.len == 2);
            assert(val.len == 1);

            try rules.put(key[0..2].*, val[0]);
        }
    }

    var map = Memo.init(gpa); 
    defer map.deinit();

    const part1 = calcScoreAtDepth(&map, template, rules, 10);
    const part2 = calcScoreAtDepth(&map, template, rules, 40);

    print("part1={}, part2={}\n", .{part1, part2});
}

fn calcScoreAtDepth(map: *Memo, template: []const u8, rules: Rules, depth: u8) u64 {
    const counts: [26]u64 = blk: {
        var counts: Result = std.mem.zeroes(Result);
        var i: usize = 0;
        while (i < template.len - 1) : (i += 1) {
            const key = template[i..][0..2].*;
            counts += count(map, rules, key, depth);
        }
        counts[template[template.len-1] - 'A'] += 1;
        break :blk counts;
    };

    var max_count: u64 = 0;
    var min_count: u64 = std.math.maxInt(u64);

    for (counts) |c| {
        if (c != 0 and c < min_count) {
            min_count = c;
        }
        if (c > max_count) {
            max_count = c;
        }
    }

    return max_count - min_count;
}

fn count(map: *Memo, rules: Rules, pair: [2]u8, depth: u8) Result {
    if (depth == 0) {
        var result = std.mem.zeroes(Result);
        result[pair[0] - 'A'] = 1;
        return result;
    }

    if (map.get(.{ .pair = pair, .depth = depth })) |val| return val;

    const insert = rules.get(pair).?;
    const result = count(map, rules, .{pair[0], insert}, depth - 1) +
        count(map, rules, .{insert, pair[1]}, depth - 1);

    map.put(.{ .pair = pair, .depth = depth}, result) catch unreachable;
    return result;
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
