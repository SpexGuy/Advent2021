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

const Rules = std.AutoArrayHashMap([2]u8, u8);

const CountsArr = [26]u64;
const CountsVec = std.meta.Vector(26, u64);

const PairId = u8;

const Link = struct {
    left: PairId,
    right: PairId,
};

const Parts = struct {
    part1: u64,
    part2: u64,
};

pub fn main() !void {
    var template: []const u8 = undefined;
    var rules = Rules.init(gpa);
    defer rules.deinit();
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

    bench(eager, rules, template, "eager");
    bench(fungible, rules, template, "fungible");
    bench(lazy, rules, template, "lazy");

    const result = fungible(rules, template);
    print("part1={}, part2={}\n", .{result.part1, result.part2});
}

fn bench(comptime func: fn (Rules, []const u8) Parts, rules: Rules, template: []const u8, name: []const u8) void {
    var i: usize = 0;
    var best_time: usize = std.math.maxInt(usize);
    var total_time: usize = 0;
    const num_runs = 1000;
    while (i < num_runs) : (i += 1) {
        const timer = std.time.Timer.start() catch unreachable;
        const parts = func(rules, template);
        std.mem.doNotOptimizeAway(&parts);
        const lap_time = timer.read();
        if (best_time > lap_time) best_time = lap_time;
        total_time += lap_time;
    }
    print("min {} avg {} {s}\n", .{best_time, total_time / num_runs, name});
}

fn eager(rules: Rules, template: []const u8) Parts {
    const pairs = rules.keys();
    const inserts = rules.values();
    const links = gpa.alloc(Link, pairs.len) catch unreachable;
    defer gpa.free(links);
    var counts = gpa.alloc(CountsArr, pairs.len) catch unreachable;
    defer gpa.free(counts);
    var next_counts = gpa.alloc(CountsArr, pairs.len) catch unreachable;
    defer gpa.free(next_counts);

    for (links) |*link, i| {
        link.left = @intCast(u8, rules.getIndex(.{pairs[i][0], inserts[i]}).?);
        link.right = @intCast(u8, rules.getIndex(.{inserts[i], pairs[i][1]}).?);
        std.mem.set(u64, &counts[i], 0);
        counts[i][pairs[i][0] - 'A'] = 1;
    }

    var depth: usize = 0;
    while (depth < 10) : (depth += 1) {
        for (links) |link, i| {
            const left: CountsVec = counts[link.left];
            const right: CountsVec = counts[link.right];
            next_counts[i] = left + right;
        }

        const tmp = counts;
        counts = next_counts;
        next_counts = tmp;
    }

    const part1 = calcScore(template, rules, counts);

    while (depth < 40) : (depth += 1) {
        for (links) |link, i| {
            const left: CountsVec = counts[link.left];
            const right: CountsVec = counts[link.right];
            next_counts[i] = left + right;
        }

        const tmp = counts;
        counts = next_counts;
        next_counts = tmp;
    }

    const part2 = calcScore(template, rules, counts);

    return .{ .part1 = part1, .part2 = part2 };
}

fn fungible(rules: Rules, template: []const u8) Parts {
    const pairs = rules.keys();
    const inserts = rules.values();
    const links = gpa.alloc(Link, pairs.len) catch unreachable;
    defer gpa.free(links);
    var counts = gpa.alloc(u64, pairs.len) catch unreachable;
    defer gpa.free(counts);
    var next_counts = gpa.alloc(u64, pairs.len) catch unreachable;
    defer gpa.free(next_counts);

    for (links) |*link, i| {
        link.left = @intCast(u8, rules.getIndex(.{pairs[i][0], inserts[i]}).?);
        link.right = @intCast(u8, rules.getIndex(.{inserts[i], pairs[i][1]}).?);
    }

    std.mem.set(u64, counts, 0);
    for (template[0..template.len-1]) |_, i| {
        const pair = template[i..][0..2].*;
        const idx = rules.getIndex(pair).?;
        counts[idx] += 1;
    }

    var depth: usize = 0;
    while (depth < 10) : (depth += 1) {
        std.mem.set(u64, next_counts, 0);
        for (links) |link, i| {
            const amt = counts[i];
            next_counts[link.left] += amt;
            next_counts[link.right] += amt;
        }

        const tmp = counts;
        counts = next_counts;
        next_counts = tmp;
    }

    const part1 = calcScoreForward(pairs, counts, template[template.len-1]);

    while (depth < 40) : (depth += 1) {
        std.mem.set(u64, next_counts, 0);
        for (links) |link, i| {
            const amt = counts[i];
            next_counts[link.left] += amt;
            next_counts[link.right] += amt;
        }

        const tmp = counts;
        counts = next_counts;
        next_counts = tmp;
    }

    const part2 = calcScoreForward(pairs, counts, template[template.len-1]);

    return .{ .part1 = part1, .part2 = part2 };
}

fn calcScoreForward(pairs: []const [2]u8, counts: []const u64, last_char: u8) u64 {
    var scores = std.mem.zeroes([26]usize);
    for (counts) |c, i| {
        scores[pairs[i][0] - 'A'] += c;
    }
    scores[last_char - 'A'] += 1;

    var max_count: u64 = 0;
    var min_count: u64 = std.math.maxInt(u64);

    for (scores) |c| {
        if (c != 0 and c < min_count) {
            min_count = c;
        }
        if (c > max_count) {
            max_count = c;
        }
    }

    return max_count - min_count;
}

fn lazy(rules: Rules, template: []const u8) Parts {
    var map = Memo.init(gpa); 
    defer map.deinit();

    const part1 = calcScoreAtDepth(&map, template, rules, 10);
    const part2 = calcScoreAtDepth(&map, template, rules, 40);

    return .{ .part1 = part1, .part2 = part2 };
}

fn calcScore(template: []const u8, rules: Rules, counts: []const CountsArr) u64 {
    var total_counts = std.mem.zeroes(CountsVec);
    for (template[0..template.len-1]) |_, i| {
        const pair = template[i..][0..2].*;
        const index = rules.getIndex(pair).?;
        const pair_counts: CountsVec = counts[index];
        total_counts += pair_counts;
    }

    var counts_arr: CountsArr = total_counts;
    counts_arr[template[template.len-1] - 'A'] += 1;

    var max_count: u64 = 0;
    var min_count: u64 = std.math.maxInt(u64);

    for (counts_arr) |c| {
        if (c != 0 and c < min_count) {
            min_count = c;
        }
        if (c > max_count) {
            max_count = c;
        }
    }

    return max_count - min_count;
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
