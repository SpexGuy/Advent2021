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

const data = @embedFile("../data/day13.txt");
const data2 =
\\6,10
\\0,14
\\9,10
\\0,3
\\10,4
\\4,11
\\6,0
\\6,12
\\4,1
\\0,13
\\10,12
\\3,4
\\3,0
\\8,4
\\1,10
\\2,14
\\8,10
\\9,0
\\
\\fold along y=7
\\fold along x=5
\\
;

const Axis = enum { x, y };
const Point = struct { x: int, y: int };
const Fold = struct { axis: Axis, value: int };

pub fn main() !void {
    var points: []Point = undefined;
    var folds: []Fold = undefined;
    {
        var lines = split(u8, data, "\n");

        // Read in the points
        var pointsl = List(Point).init(gpa);
        defer pointsl.deinit();
        while (lines.next()) |line| {
            if (line.len == 0) { break; }
            var parts = tokenize(u8, line, ",\r");
            const a = parts.next().?;
            const b = parts.next().?;
            assert(parts.next() == null);
            try pointsl.append(.{
                .x = parseInt(int, a, 10) catch unreachable,
                .y = parseInt(int, b, 10) catch unreachable,
            });
        }
        points = pointsl.toOwnedSlice();

        // Read in the folds
        var foldsl = List(Fold).init(gpa);
        defer foldsl.deinit();
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            var parts = tokenize(u8, line, "fold ang=\r"); // let tokenize eat the english
            const axis = parts.next().?;
            const dist = parts.next().?;
            assert(parts.next() == null);
            try foldsl.append(.{
                .axis = parseEnum(Axis, axis) orelse unreachable,
                .value = parseInt(int, dist, 10) catch unreachable,
            });
        }
        folds = foldsl.toOwnedSlice();
    }

    // Do the folds and track page size
    var part1: usize = 0;
    var width: usize = 0;
    var height: usize = 0;
    for (folds) |fold, i| {
        // Fold each point
        for (points) |*point| {
            switch (fold.axis) {
                .x => {
                    point.x = fold.value - (std.math.absInt(point.x - fold.value) catch unreachable);
                    width = @intCast(usize, fold.value + 1);
                },
                .y => {
                    point.y = fold.value - (std.math.absInt(point.y - fold.value) catch unreachable);
                    height = @intCast(usize, fold.value + 1);
                },
            }
        }

        // Calculate part 1 after the first fold
        if (i == 0) {
            var set = Map(Point, void).init(gpa);
            defer set.deinit();
            try set.ensureUnusedCapacity(@intCast(u32, points.len));
            for (points) |p| {
                set.putAssumeCapacity(p, {});
            }
            part1 = set.count();
        }
    }

    // Allocate a scanout buffer and initialize it as blank lines
    const pixel_width = 2;
    const pitch = width * pixel_width + 1;
    const buf = try gpa.alloc(u8, pitch * height);
    defer gpa.free(buf);
    {
        std.mem.set(u8, buf, ' ');
        var y: usize = 0;
        while (y < height) : (y += 1) {
            buf[y*pitch + (pitch-1)] = '\n';
        }
    }

    // Mark all the points
    for (points) |p| {
        const x = @intCast(usize, p.x);
        const y = @intCast(usize, p.y);
        assert(x < width);
        assert(y < height);
        const idx = y * pitch + x * pixel_width;
        buf[idx..][0..pixel_width].* = ("#" ** pixel_width).*;
    }

    print("part1={}, part2=\n{s}\n", .{part1, buf});
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
