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

const logging = false;
const data = @embedFile("../data/day18.txt");

const Item = struct {
    depth: u8,
    number: u8,
};

pub fn main() !void {
    var timer = try std.time.Timer.start();

    var snail_bois = blk: {
        var snailies = std.ArrayList([]const Item).init(gpa);
        errdefer snailies.deinit();
        var parsed = std.ArrayList(Item).init(gpa);
        defer parsed.deinit();
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }

            parsed.clearRetainingCapacity();
            try parsed.ensureTotalCapacity(line.len);

            var depth: u8 = 0;
            for (line) |char| {
                switch (char) {
                    '[' => depth += 1,
                    ']' => depth -= 1,
                    ',' => {},
                    '0'...'9' => try parsed.append(.{ .depth = depth, .number = char - '0' }),
                    else => unreachable,
                }
            }

            try snailies.append(try gpa.dupe(Item, parsed.items));
        }
        break :blk snailies.toOwnedSlice();
    };
    defer gpa.free(snail_bois);
    defer for (snail_bois) |it| {
        gpa.free(it);
    };

    const parse_time = timer.lap();

    var total = try addNumbers(snail_bois[0], snail_bois[1]);
    for (snail_bois[2..]) |it| {
        const next = try addNumbers(total, it);
        gpa.free(total);
        total = next;
    }
    const part1 = magnitude(total);
    gpa.free(total);

    const part1_time = timer.lap();

    var part2: u64 = 0;
    for (snail_bois) |a| {
        for (snail_bois) |b| {
            const p0 = try addNumbers(a, b);
            const mag = magnitude(p0);
            gpa.free(p0);
            if (mag > part2) part2 = mag;
        }
    }

    const part2_time = timer.read();

    print("part1={}, part2={}\n", .{part1, part2});
    print("times: parse={}, part1={}, part2={} total={}\n", .{parse_time, part1_time, part2_time, parse_time + part1_time + part2_time});
}

fn magnitude(value: []const Item) u64 {
    const State = struct {
        val: []const Item,
        pos: usize = 0,

        fn calc(self: *@This(), depth: u8) u64 {
            const it = self.val[self.pos];
            assert(it.depth >= depth);
            if (depth == it.depth) {
                self.pos += 1;
                return it.number;
            } else {
                const a = self.calc(depth + 1);
                const b = self.calc(depth + 1);
                return a * 3 + b * 2;
            }
        }
    };

    var state = State{ .val = value };
    const result = state.calc(0);
    assert(state.pos == value.len);
    return result;
}

fn printItems(value: []const Item) void {
    const State = struct {
        val: []const Item,
        pos: usize = 0,

        fn printRec(self: *@This(), depth: u8) void {
            const it = self.val[self.pos];
            assert(it.depth >= depth);
            if (depth == it.depth) {
                self.pos += 1;
                print("{}", .{it.number});
            } else {
                print("[", .{});
                self.printRec(depth + 1);
                print(",", .{});
                self.printRec(depth + 1);
                print("]", .{});
            }
        }
    };

    var state = State{ .val = value };
    const result = state.printRec(0);
    print("\n", .{});
    assert(state.pos == value.len);
    return result;
}

fn addNumbers(a: []const Item, b: []const Item) ![]const Item {
    if (logging) printItems(a);
    if (logging) printItems(b);

    var output = std.ArrayList(Item).init(gpa);
    errdefer output.deinit();
    try output.ensureTotalCapacity(a.len + b.len);

    try output.appendSlice(a);
    try output.appendSlice(b);
    for (output.items) |*it| {
        it.depth += 1;
    }

    {
        var i: usize = 0;
        while (i < output.items.len) : (i += 1) {
            const it = output.items[i];
            if (it.depth >= 5) {
                assert(it.depth == 5);
                assert(output.items[i+1].depth == 5);
                if (i > 0) {
                    output.items[i-1].number += it.number;
                }
                if (i + 2 < output.items.len) {
                    output.items[i+2].number += output.items[i+1].number;
                }
                _ = output.orderedRemove(i+1);
                output.items[i] = .{ .number = 0, .depth = 4 };
            }
        }
    }

    {
        var i: usize = 0;
        while (i < output.items.len) {
            const it = output.items[i];
            if (it.number >= 10) {
                const left = it.number / 2;
                const right = (it.number + 1) / 2;
                if (it.depth == 4) {
                    if (i+1 < output.items.len) {
                        output.items[i+1].number += right;
                    }
                    output.items[i].number = 0;
                    if (i > 0) {
                        output.items[i-1].number += left;
                        i -= 1;
                    }
                } else {
                    output.items[i] = .{ .depth = it.depth + 1, .number = left };
                    try output.insert(i+1, .{ .depth = it.depth + 1, .number = right });
                }
            } else {
                i += 1;
            }
        }
    }

    if (logging) printItems(output.items);
    if (logging) print("\n", .{});

    return output.toOwnedSlice();
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
