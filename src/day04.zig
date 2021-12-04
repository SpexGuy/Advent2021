const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day04.txt");

const Board = struct {
    numbers: [25]u8,
    marked: u25 = 0,
    won: bool = false,
};

pub fn main() !void {
    var segments = tokenize(u8, data, "\r\n ");

    var draws = blk: {
        var drawing_parts = tokenize(u8, segments.next().?, ",");
        var draws = List(u8).init(gpa);
        while(drawing_parts.next()) |part| {
            draws.append(try parseInt(u8, part, 10)) catch unreachable;
        }
        break :blk draws.toOwnedSlice();
    };

    const boards = blk: {
        var boards = List(Board).init(gpa);
        while (true) {
            var b: Board = .{ .numbers = undefined };
            var i: usize = 0; while (i < 25) : (i += 1) {
                const line = segments.next() orelse{
                    assert(i == 0);
                    break :blk boards.toOwnedSlice();
                };

                b.numbers[i] = try parseInt(u8, line, 10);
            }
            try boards.append(b);
        }
    };

    var part1: u32 = 0;
    var part2: u32 = 0;
    var boards_remain = boards.len;

    next_draw: for (draws) |drawn| {
        for (boards) |*board| {
            if (!board.won) {
                next_number: for (board.numbers) |*it, index| {
                    if (it.* == drawn) {
                        const bit = @as(u25, 1) << @intCast(u5, index);
                        board.marked |= bit;

                        if (hasWon(board.*)) {
                            if (part1 == 0) part1 = score(board.*) * drawn;
                            board.won = true;
                            boards_remain -= 1;
                            if (boards_remain == 0) {
                                part2 = score(board.*) * drawn;
                                break :next_draw;
                            }
                            continue :next_number;
                        }
                    }
                }
            }
        }
    } else unreachable; // unfinished boards?

    print("part1={}, part2={}\n", .{part1, part2});
}

fn hasWon(b: Board) bool {
    const success_patterns = [_]u25 {
        0b1000010000100001000010000,
        0b0100001000010000100001000,
        0b0010000100001000010000100,
        0b0001000010000100001000010,
        0b0000100001000010000100001,
        0b1111100000000000000000000,
        0b0000011111000000000000000,
        0b0000000000111110000000000,
        0b0000000000000001111100000,
        0b0000000000000000000011111,
    };

    for (success_patterns) |pat| {
        if (b.marked & pat == pat) {
            return true;
        }
    }
    return false;
}

fn score(b: Board) u32 {
    var total: u32 = 0;
    for (b.numbers) |it, i| {
        const bit = @as(u25, 1) << @intCast(u5, i);
        if (bit & b.marked == 0) {
            total += it;
        }
    }
    return total;
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
