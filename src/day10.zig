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

const data = @embedFile("../data/day10.txt");

pub fn main() !void {
    var part1: usize = 0;

    var completion_scores = blk: {
        var completion_scores = List(usize).init(gpa);
        errdefer completion_scores.deinit();

        var lines = tokenize(u8, data, "\r\n");
        next_line: while (lines.next()) |line| {
            var state = std.ArrayList(u8).init(gpa);
            defer state.deinit();
            for (line) |c| {
                switch (c) {
                    '(' => try state.append(')'),
                    '{' => try state.append('}'),
                    '<' => try state.append('>'),
                    '[' => try state.append(']'),
                    else => if (state.items.len == 0 or state.pop() != c) {
                        switch (c) {
                            ')' => part1 += 3,
                            ']' => part1 += 57,
                            '}' => part1 += 1197,
                            '>' => part1 += 25137,
                            else => unreachable,
                        }
                        continue :next_line;
                    },
                }
            }

            var score: usize = 0;
            while (state.popOrNull()) |comp| {
                score = score * 5;
                switch (comp) {
                    ')' => score += 1,
                    ']' => score += 2,
                    '}' => score += 3,
                    '>' => score += 4,
                    else => unreachable,
                }
            }
            try completion_scores.append(score);
        }
        break :blk completion_scores.toOwnedSlice();
    };
    defer gpa.free(completion_scores);

    sort(usize, completion_scores, {}, comptime asc(usize));
    assert(completion_scores.len % 2 == 1);
    const part2 = completion_scores[completion_scores.len / 2];

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
