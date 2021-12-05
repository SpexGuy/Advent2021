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

const data = @embedFile("../data/day05.txt");

const Point = struct { x: int, y: int };

const VentLine = struct {
    start: Point,
    end: Point,
};

const VentMap = struct {
    map: Map(Point, int) = Map(Point, int).init(gpa),
    overlaps: int = 0,

    pub fn mark(self: *VentMap, x: int, y: int) void {
        const pt = Point{ .x = x, .y = y };
        const result = self.map.getOrPut(pt) catch unreachable;
        if (result.found_existing) {
            if (result.value_ptr.* == 1) {
                self.overlaps += 1;
            }
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }
};

pub fn main() !void {
    var vents = blk: {
        var vents = List(VentLine).init(gpa);
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) {continue;}
            var parts = tokenize(u8, line, " ,->");
            vents.append(.{
                .start = .{
                    .x = try parseInt(int, parts.next().?, 10),
                    .y = try parseInt(int, parts.next().?, 10),
                },
                .end = .{
                    .x = try parseInt(int, parts.next().?, 10),
                    .y = try parseInt(int, parts.next().?, 10),
                },
            }) catch unreachable;
            assert(parts.next() == null);
        }
        break :blk vents.toOwnedSlice();
    };

    var map: VentMap = .{};

    for (vents) |it| {
        if (it.start.x == it.end.x) {
            // horizontal line
            var curr_y = min(it.start.y, it.end.y);
            const end_y = max(it.start.y, it.end.y);
            while (curr_y <= end_y) : (curr_y += 1) {
                map.mark(it.start.x, curr_y);
            }
        } else if (it.start.y == it.end.y) {
            // vertical line
            var curr_x = min(it.start.x, it.end.x);
            const end_x = max(it.start.x, it.end.x);
            while (curr_x <= end_x) : (curr_x += 1) {
                map.mark(curr_x, it.start.y);
            }
        }
    }

    const part1 = map.overlaps;

    for (vents) |it| {
        if (it.start.x != it.end.x and it.start.y != it.end.y) {
            // diagonal line
            var curr_x = it.start.x;
            var end_x = it.end.x;
            var x_incr: int = if (curr_x < end_x) 1 else -1;
            var curr_y = it.start.y;
            var end_y = it.end.y;
            var y_incr: int = if (curr_y < end_y) 1 else -1;
            assert(end_x == curr_x + (end_y - curr_y) * y_incr * x_incr);

            while (curr_y - y_incr != end_y) : ({
                curr_x += x_incr;
                curr_y += y_incr;
            }) {
                map.mark(curr_x, curr_y);
            }
        }
    }

    const part2 = map.overlaps;

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
