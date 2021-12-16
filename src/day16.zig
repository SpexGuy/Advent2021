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

const data = @embedFile("../data/day16.txt");

const PacketType = enum {
    add,
    mul,
    min,
    max,
    lit,
    cgt,
    clt,
    ceq,
};

const BitIter = struct {
    position: usize = 0,
    str: []const u8,
    word: u4 = 0,
    remain: u8 = 0,
    part1: u32 = 0,

    pub fn nextBit(self: *@This()) u1 {
        if (self.remain == 0) {
            const char = self.str[0];
            self.str = self.str[1..];
            const word = switch (char) {
                '0'...'9' => @intCast(u4, char - '0'),
                'A'...'F' => @intCast(u4, char - 'A' + 10),
                else => unreachable,
            };
            self.word = @bitReverse(u4, word);
            self.remain = 4;
        }

        self.position += 1;
        self.remain -= 1;
        const bit = self.word & 1;
        self.word = self.word >> 1;
        return @intCast(u1, bit);
    }

    pub fn nextBits(self: *@This(), len: usize) u32 {
        var result: u32 = 0;
        var i: usize = 0;
        while (i < len) : (i += 1) {
            result <<= 1;
            result |= self.nextBit();
        }
        return result;
    }

    pub fn packet(self: *@This()) u64 {
        const version = self.nextBits(3);
        const type_id = @intToEnum(PacketType, self.nextBits(3));
        self.part1 += version;
        return switch (type_id) {
            .lit => self.literal(),
            .cgt, .clt, .ceq => self.compare(type_id),
            .add, .mul, .min, .max => self.operator(type_id),
        };
    }

    pub fn literal(self: *@This()) u64 {
        var value: u64 = 0;
        while (true) {
            const chunk = self.nextBits(5);
            value <<= 4;
            value |= chunk & 0xF;
            if (chunk & 0x10 == 0) break;
        }
        return value;
    }

    pub fn compare(self: *@This(), type_id: PacketType) u64 {
        const len_bit = self.nextBit();
        _ = self.nextBits(if (len_bit == 0) 15 else 11);
        const left = self.packet();
        const right = self.packet();
        return switch (type_id) {
            .cgt => @boolToInt(left > right),
            .clt => @boolToInt(left < right),
            .ceq => @boolToInt(left == right),
            else => unreachable,
        };
    }

    pub fn operator(self: *@This(), type_id: PacketType) u64 {
        const len_bit = self.nextBit();
        var result: usize = switch (type_id) {
            .add => 0,
            .mul => 1,
            .min => std.math.maxInt(u64),
            .max => 0,
            else => unreachable,
        };
        if (len_bit == 0) {
            const total = self.nextBits(15);
            const end = self.position + total;
            while (self.position != end) {
                const it = self.packet();
                switch (type_id) {
                    .add => result += it,
                    .mul => result *= it,
                    .min => result = min(result, it),
                    .max => result = max(result, it),
                    else => unreachable,
                }
            }
        } else {
            const number = self.nextBits(11);
            var i: u32 = 0;
            while (i < number) : (i += 1) {
                const it = self.packet();
                switch (type_id) {
                    .add => result += it,
                    .mul => result *= it,
                    .min => result = min(result, it),
                    .max => result = max(result, it),
                    else => unreachable,
                }
            }
        }
        return result;
    }
};

pub fn main() !void {
    var iter = BitIter{ .str = data };
    const part2 = iter.packet();
    const part1 = iter.part1;
    print("part1={}, part2={}\n", .{ part1, part2 });
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
