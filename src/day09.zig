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

const data = @embedFile("../data/day09.txt");

const Rec = struct {
    val: int,
};

pub fn main() !void {
    var width: usize = 0;
    var height: usize = 0;
    // Load the map with a border of 9 values
    const height_map = blk: {
        var height_map = List(u8).init(gpa);
        errdefer height_map.deinit();
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            if (width == 0) {
                width = line.len;
                try height_map.appendNTimes(9, width + 2);
            } else {
                assert(width == line.len);
            }

            try height_map.append(9);

            for (line) |c| {
                try height_map.append(c - '0');
            }
            height += 1;

            try height_map.append(9);
        }
        try height_map.appendNTimes(9, width + 2);
        break :blk height_map.toOwnedSlice();
    };
    defer gpa.free(height_map);

    const pitch = width + 2;
    const start = pitch + 1;

    var basin_map = try gpa.alloc(u8, height_map.len);
    defer gpa.free(basin_map);
    @memset(basin_map.ptr, 0, basin_map.len);

    for (height_map) |rec, i| {
        if (rec == 9) {
            basin_map[i] = 1;
        }
    }

    var big1_count: usize = 0;
    var big2_count: usize = 0;
    var big3_count: usize = 0;

    var basin_id: u8 = 2;

    var part1: usize = 0;
    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            const idx = y * pitch + x + start;
            const left = height_map[idx - 1];
            const up = height_map[idx - pitch];
            const down = height_map[idx + pitch];
            const right = height_map[idx + 1];
            const self = height_map[idx];
            if (self < left and
                self < right and
                self < down and
                self < up)
            {
                part1 += self + 1;

                const count = try floodFill(basin_map, pitch, idx, basin_id);
                basin_id += 1;

                if (count > big1_count) {
                    big3_count = big2_count;
                    big2_count = big1_count;
                    big1_count = count;
                } else if (count > big2_count) {
                    big3_count = big2_count;
                    big2_count = count;
                } else if (count > big3_count) {
                    big3_count = count;
                }
            }
        }
    }

    const part2 = @intCast(int, big1_count * big2_count * big3_count);

    print("part1={}, part2={}\n", .{part1, part2});
}

fn floodFill(map: []u8, pitch: usize, seed_idx: usize, basin_id: u8) !usize {
    var frontier = std.ArrayList(usize).init(gpa);
    defer frontier.deinit();

    try frontier.append(seed_idx);

    var count: usize = 0;

    while (frontier.popOrNull()) |idx| {
        if (map[idx] != 0) continue;

        map[idx] = basin_id;
        count += 1;
        
        const left = map[idx - 1];
        const up = map[idx - pitch];
        const down = map[idx + pitch];
        const right = map[idx + 1];

        if (left == 0) try frontier.append(idx - 1);
        if (up == 0) try frontier.append(idx - pitch);
        if (down == 0) try frontier.append(idx + pitch);
        if (right == 0) try frontier.append(idx + 1);
    }

    return count;
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
