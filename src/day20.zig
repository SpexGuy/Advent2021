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

const data = @embedFile("../data/day20.txt");

const Image = struct {
    key: *const [512]u8,
    grid: []u8,
    start: usize,
    pitch: usize,
    width: usize,
    height: usize,
    default: u8 = '.',

    pub fn deinit(self: *@This()) void {
        gpa.free(self.grid);
        self.* = undefined;
    }

    pub fn enhance(self: *@This()) void {
        // Figure out the next default
        self.default = if (self.default == '.') self.key[0] else self.key[0b111_111_111];

        // Allocate a one larger grid with a border
        const new_width = self.width + 2;
        const new_height = self.height + 2;
        const new_pitch = new_width + 2;
        const new_start = new_pitch + 1;
        const new_grid = gpa.alloc(u8, @intCast(usize, new_pitch * (new_height + 2))) catch unreachable;

        // Set the new border to the default
        {
            @memset(new_grid.ptr, self.default, new_pitch * 2);
            @memset(new_grid.ptr + new_grid.len - 2 * new_pitch, self.default, 2 * new_pitch);
            var y: usize = 0;
            while (y < new_height) : (y += 1) {
                const base = (y+1) * new_pitch + new_start;
                new_grid[base - 1] = self.default;
                new_grid[base] = self.default;
                new_grid[base + new_width - 1] = self.default;
                new_grid[base + new_width] = self.default;
            }
        }

        // Update image
        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                const in_center = y * self.pitch + x + self.start;
                const out_center = (y + 1) * new_pitch + (x + 1) + new_start;
                var lookup_id: u32 = 0;
                if (self.grid[in_center - self.pitch - 1] == '#') lookup_id |= (1<<8);
                if (self.grid[in_center - self.pitch    ] == '#') lookup_id |= (1<<7);
                if (self.grid[in_center - self.pitch + 1] == '#') lookup_id |= (1<<6);
                if (self.grid[in_center              - 1] == '#') lookup_id |= (1<<5);
                if (self.grid[in_center                 ] == '#') lookup_id |= (1<<4);
                if (self.grid[in_center              + 1] == '#') lookup_id |= (1<<3);
                if (self.grid[in_center + self.pitch - 1] == '#') lookup_id |= (1<<2);
                if (self.grid[in_center + self.pitch    ] == '#') lookup_id |= (1<<1);
                if (self.grid[in_center + self.pitch + 1] == '#') lookup_id |= (1<<0);
                new_grid[out_center] = self.key[lookup_id];
            }
        }

        // Persist results
        gpa.free(self.grid);
        self.grid = new_grid;
        self.width = new_width;
        self.height = new_height;
        self.start = new_start;
        self.pitch = new_pitch;
    }

    pub fn countLit(self: @This()) usize {
        assert(self.default == '.');
        var total: usize = 0;
        for (self.grid) |c| {
            if (c == '#') total += 1;
        }
        return total;
    }
};

pub fn main() !void {
    var timer = try std.time.Timer.start();

    var grid = blk: {
        var width: usize = 0;
        var height: usize = 0;
        var height_map = List(u8).init(gpa);
        errdefer height_map.deinit();
        var lines = tokenize(u8, data, "\r\n");
        const key = lines.next().?[0..512];
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            if (width == 0) {
                width = line.len;
                try height_map.appendNTimes('.', (width + 4) * 2);
            } else {
                assert(width == line.len);
            }

            try height_map.appendNTimes('.', 2);

            for (line) |c| {
                try height_map.append(c);
            }
            height += 1;

            try height_map.appendNTimes('.', 2);
        }
        try height_map.appendNTimes('.', (width + 4) * 2);
        break :blk Image{
            .key = key,
            .grid = height_map.toOwnedSlice(),
            .width = width + 2,
            .height = height + 2,
            .pitch = width + 4,
            .start = width + 5,
        };
    };
    defer grid.deinit();

    const parse_time = timer.lap();

    var i: usize = 0;
    while (i < 2) : (i += 1) {
        grid.enhance();
    }
    const part1 = grid.countLit();

    const part1_time = timer.lap();

    while (i < 50) : (i += 1) {
        grid.enhance();
    }
    const part2 = grid.countLit();

    const part2_time = timer.lap();

    print("part1={}, part2={}\n", .{part1, part2});
    print("Timing: parse={}, part1={}, part2={}, total={}\n", .{parse_time, part1_time, part2_time, parse_time + part1_time + part2_time});
}

fn printGrid(grid: []const u8, pitch: usize) void {
    var i: usize = 0;
    while (i < grid.len) : (i += pitch) {
        print("{s}\n", .{grid[i..][0..pitch]});
    }
    print("\n", .{});
    assert(i == grid.len);
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
