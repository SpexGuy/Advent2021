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

const data = @embedFile("../data/day11.txt");

const Rec = struct {
    val: int,
};

pub fn main() !void {
    var width: usize = 0;
    var height: usize = 0;
    // Load the map with a border of 9 values
    const map = blk: {
        var map = List(u8).init(gpa);
        errdefer map.deinit();
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            if (width == 0) {
                width = line.len;
                try map.appendNTimes(9, width + 2);
            } else {
                assert(width == line.len);
            }

            try map.append(9);

            for (line) |c| {
                try map.append(c - '0');
            }
            height += 1;

            try map.append(9);
        }
        try map.appendNTimes(9, width + 2);
        break :blk map.toOwnedSlice();
    };
    defer gpa.free(map);

    const pitch = width + 2;
    const start = pitch + 1;

    var flashes = std.ArrayList(usize).init(gpa);
    defer flashes.deinit();

    var part1: usize = 0;
    var day: usize = 0;
    var all_flash_day: ?usize = null;
    while (day < 100 or all_flash_day == null) : (day += 1) {
        // Clear the border
        {
            std.mem.set(u8, map[0..pitch], 0);
            std.mem.set(u8, map[pitch + pitch*height..], 0);
            var y: usize = 0;
            while (y < height) : (y += 1) {
                const offset = pitch + pitch * y;
                map[offset] = 0;
                map[offset + pitch - 1] = 0;
            }
        }

        var flashes_this_day: usize = 0;

        // All octopuses gain 1 charge
        {
            var y: usize = 0;
            while (y < height) : (y += 1) {
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    const idx = y * pitch + x + start;

                    map[idx] += 1;
                    if (map[idx] == 10) {
                        flashes_this_day += 1;
                        try flashes.append(idx);
                    }
                }
            }
        }

        // Flashing octopuses increase charge of neighbors
        while (flashes.popOrNull()) |flash| {
            const neighbors = [_]usize {
                flash - pitch - 1,
                flash - pitch,
                flash - pitch + 1,
                flash - 1,
                flash + 1,
                flash + pitch - 1,
                flash + pitch,
                flash + pitch + 1,
            };
            for (neighbors) |neigh| {
                map[neigh] += 1;
                if (map[neigh] == 10) {
                    flashes_this_day += 1;
                    try flashes.append(neigh);
                }
            }
        }

        // Update condition counters
        if (day < 100) {
            part1 += flashes_this_day;
        }
        if (all_flash_day == null and flashes_this_day == width * height) {
            all_flash_day = day;
        }

        // Reset the border to avoid fake flashes from it
        {
            var y: usize = 0;
            while (y < height) : (y += 1) {
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    const idx = y * pitch + x + start;
                    if (map[idx] > 9) map[idx] = 0;
                }
            }
        }
    }

    const part2 = all_flash_day.? + 1;

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
