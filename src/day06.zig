const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day06.txt");

const Fishes = struct {
    ages: [9]u64 = [_]u64{0} ** 9,

    fn nextDay(self: *Fishes) void {
        var next: Fishes = .{};
        next.ages[0] = self.ages[1];
        next.ages[1] = self.ages[2];
        next.ages[2] = self.ages[3];
        next.ages[3] = self.ages[4];
        next.ages[4] = self.ages[5];
        next.ages[5] = self.ages[6];
        next.ages[6] = self.ages[7] + self.ages[0];
        next.ages[7] = self.ages[8];
        next.ages[8] = self.ages[0];
        self.* = next;
    }

    fn totalFish(self: Fishes) u64 {
        var total: u64 = 0;
        for (self.ages) |count| {
            total += count;
        }
        return total;
    }
};

pub fn main() !void {
    var fish: Fishes = .{};

    var fish_it = tokenize(u8, data, ",\r\n");
    while (fish_it.next()) |fish_age| {
        const age = parseInt(u8, fish_age, 10) catch unreachable;
        fish.ages[age] += 1;
    }

    var day: usize = 0;
    while (day < 80) : (day += 1) {
        fish.nextDay();
    }

    const part1 = fish.totalFish();

    while (day < 256) : (day += 1) {
        fish.nextDay();
    }

    const part2 = fish.totalFish();

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
