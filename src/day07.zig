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

const data = @embedFile("../data/day07.txt");
//const data = "16,1,2,0,4,2,7,1,2,14";

const Record = struct {
    pos: int,
};

pub fn main() !void {
    const positions = blk: {
        var recs = List(int).init(gpa);
        var iter = tokenize(u8, data, "\r\n,");
        while (iter.next()) |num| {
            if (num.len == 0) { continue; }

            const dist = try parseInt(int, num, 10);
            try recs.append(dist);
        }
        break :blk recs.toOwnedSlice();
    };

    sort(int, positions, {}, comptime asc(int));

    const part1_pos = positions[positions.len / 2];
    var part1: int = 0;
    for (positions) |rec| {
        part1 += std.math.absInt(rec - part1_pos) catch unreachable;
    }

    // Estimate part 2 start position
    var part2_pos = part1_pos;
    // Determine gradient direction
    var curr_cost = calculateCost(positions, part2_pos);
    var asc_cost = calculateCost(positions, part2_pos + 1);
    var part2_incr: int = -1;
    if (curr_cost > asc_cost) {
        part2_incr = 1;
        curr_cost = asc_cost;
        part2_pos += 1;
    }

    // Walk down gradient until we hit the minimum
    var steps: usize = 0;
    while (true) {
        const next_cost = calculateCost(positions, part2_pos + part2_incr);
        if (next_cost > curr_cost) {
            break;
        } else {
            curr_cost = next_cost;
            part2_pos += part2_incr;
        }
        steps += 1;
    }

    const part2 = curr_cost;

    print("part1={}, part2={}\n", .{part1, part2});
}

fn calculateCost(recs: []const int, target: int) int {
    var cost: int = 0;
    for (recs) |it| {
        const diff = std.math.absInt(it - target) catch unreachable;
        cost += @divExact(diff * (diff + 1), 2);
    }
    return cost;
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
