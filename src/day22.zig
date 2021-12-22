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

const data = @embedFile("../data/day22.txt");

const Command = struct {
    op: enum{ on, off },
    bounds: Bounds,
};

const Bounds = struct {
    v: [3][2]int,

    fn size(self: @This()) usize {
        return @intCast(usize,
                (self.v[0][1] - self.v[0][0] + 1) *
                (self.v[1][1] - self.v[1][0] + 1) *
                (self.v[2][1] - self.v[2][0] + 1));
    }

    fn intersects(a: @This(), b: @This()) bool {
        return (a.v[0][0] <= b.v[0][1] and a.v[0][1] >= b.v[0][0]) and
                (a.v[1][0] <= b.v[1][1] and a.v[1][1] >= b.v[1][0]) and
                (a.v[2][0] <= b.v[2][1] and a.v[2][1] >= b.v[2][0]);
    }

    fn contains(a: @This(), b: @This()) bool {
        return (a.v[0][0] <= b.v[0][0] and a.v[0][1] >= b.v[0][1]) and
                (a.v[1][0] <= b.v[1][0] and a.v[1][1] >= b.v[1][1]) and
                (a.v[2][0] <= b.v[2][0] and a.v[2][1] >= b.v[2][1]);
    }
};

pub fn main() !void {
    var timer = try std.time.Timer.start();

    const items = util.parseLinesDelim(Command, data, " ,xyz=.");

    const parse_time = timer.lap();

    const part1_region = Bounds{ .v = [_][2]int{ .{-50, 50} } ** 3 };
    var part1_regions = std.ArrayList(Bounds).init(gpa);
    const part1_end_index = for (items) |it, i| {
        if (!part1_region.contains(it.bounds)) break i;
        try processCommand(it, &part1_regions);
    } else unreachable;

    var part1: usize = 0;
    for (part1_regions.items) |r| {
        part1 += r.size();
    }

    const part1_time = timer.lap();

    var part2_regions = std.ArrayList(Bounds).init(gpa);
    for (items[part1_end_index..]) |it| {
        try processCommand(it, &part2_regions);
    }

    var part2: usize = part1;
    for (part2_regions.items) |r| {
        part2 += r.size();
    }

    const part2_time = timer.lap();

    print("part1={}, part2={}\n", .{part1, part2});
    print("Timing: parse={}, part1={}, part2={}, total={}\n", .{parse_time, part1_time, part2_time, parse_time + part1_time + part2_time});
}

fn processCommand(cmd: Command, regions: *std.ArrayList(Bounds)) !void {
    switch (cmd.op) {
        .on => {
            var i: usize = 0;
            next_region: while (i < regions.items.len) {
                const item = regions.items[i];
                if (item.intersects(cmd.bounds)) {
                    if (item.contains(cmd.bounds)) {
                        return; // all pixels already on
                    }
                    if (cmd.bounds.contains(item)) {
                        _ = regions.swapRemove(i);
                        continue :next_region;
                    }
                    var carved = CarvedList.init(0) catch unreachable;
                    carve(&carved, item, cmd.bounds);
                    try regions.replaceRange(i, 1, carved.slice());
                    i += carved.len;
                } else {
                    i += 1;
                }
            }
            try regions.append(cmd.bounds);
        },
        .off => {
            var i: usize = 0;
            next_region: while (i < regions.items.len) {
                const item = regions.items[i];
                if (item.intersects(cmd.bounds)) {
                    if (cmd.bounds.contains(item)) {
                        _ = regions.swapRemove(i);
                        continue :next_region;
                    }
                    var carved = CarvedList.init(0) catch unreachable;
                    carve(&carved, item, cmd.bounds);
                    try regions.replaceRange(i, 1, carved.slice());
                    i += carved.len;
                } else {
                    i += 1;
                }
            }
        },
    }
}

const CarvedList = std.BoundedArray(Bounds, 6);
fn carve(result: *CarvedList, carved: Bounds, carver: Bounds) void {
    var remain = carved;
    var axis: usize = 0;
    while (axis < 3) : (axis += 1) {
        if (remain.v[axis][0] < carver.v[axis][0]) {
            var chunk = remain;
            chunk.v[axis][1] = carver.v[axis][0] - 1;
            result.appendAssumeCapacity(chunk);
            remain.v[axis][0] = carver.v[axis][0];
        }
        if (remain.v[axis][1] > carver.v[axis][1]) {
            var chunk = remain;
            chunk.v[axis][0] = carver.v[axis][1] + 1;
            result.appendAssumeCapacity(chunk);
            remain.v[axis][1] = carver.v[axis][1];
        }
    }
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
