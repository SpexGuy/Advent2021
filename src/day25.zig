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

const data = @embedFile("../data/day25.txt");

const Rec = struct {
    val: int,
};

pub fn main() !void {
    var width: usize = 0;
    var height: usize = 0;
    // Load the map with a border of 9 values
    var grid = blk: {
        var height_map = List(u8).init(gpa);
        errdefer height_map.deinit();
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            if (width == 0) {
                width = line.len;
                try height_map.appendNTimes('-', width + 2);
            } else {
                assert(width == line.len);
            }

            try height_map.append('-');

            for (line) |c| {
                try height_map.append(c);
            }
            height += 1;

            try height_map.append('-');
        }
        try height_map.appendNTimes('-', width + 2);
        break :blk height_map.toOwnedSlice();
    };
    defer gpa.free(grid);

    const pitch = width + 2;
    const start = pitch + 1;

    var next_grid = try gpa.dupe(u8, grid);
    defer gpa.free(next_grid);

    var is_moving = true;
    var part1: usize = 0;
    while (is_moving) {
        is_moving = false;
        {
            var i: usize = 0;
            while (i < height) : (i += 1) {
                @memset(next_grid.ptr + start + i*pitch, '.', width);
            }
        }

        part1 += 1;
        for (grid) |c, i| {
            if (c == '>') {
                if (grid[i+1] == '.') {
                    next_grid[i+1] = '>';
                    is_moving = true;
                } else if (grid[i+1] == '-' and grid[i+1-width] == '.') {
                    next_grid[i+1-width] = '>';
                    is_moving = true;
                } else {
                    next_grid[i] = '>';
                }
            }
            if (c == 'v') {
                next_grid[i] = 'v';
            }
        }

        {
            const tmp = next_grid;
            next_grid = grid;
            grid = tmp;

            var i: usize = 0;
            while (i < height) : (i += 1) {
                @memset(next_grid.ptr + start + i*pitch, '.', width);
            }
        }
        
        for (grid) |c, i| {
            if (c == '>') {
                next_grid[i] = '>';
            }
            if (c == 'v') {
                if (grid[i+pitch] == '.') {
                    next_grid[i+pitch] = 'v';
                    is_moving = true;
                } else if (grid[i+pitch] == '-' and grid[i+pitch-(pitch*height)] == '.') {
                    next_grid[i+pitch-(pitch*height)] = 'v';
                    is_moving = true;
                } else {
                    next_grid[i] = 'v';
                }
            }
        }

        {
            const tmp = next_grid;
            next_grid = grid;
            grid = tmp;
        }
    }

    print("part1={}\n", .{part1});
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
