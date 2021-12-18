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

const data = @embedFile("../data/day18.txt");

const Item = union(enum) {
    open: void,
    number: u8,
    close: void,
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

            for (line) |char| {
                switch (char) {
                    '[' => try parsed.append(.open),
                    ']' => try parsed.append(.close),
                    ',' => {},
                    '0'...'9' => try parsed.append(.{ .number = char - '0' }),
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

        fn next(self: *@This()) Item {
            var it = self.val[self.pos];
            self.pos += 1;
            return it;
        }

        fn calc(self: *@This()) u64 {
            switch (self.next()) {
                .open => {
                    const a = self.calc();
                    const b = self.calc();
                    assert(self.next() == .close);
                    return a * 3 + b * 2;
                },
                .number => |num| return num,
                else => unreachable,
            }
        }
    };

    return (State{ .val = value }).calc();
}

fn printItems(num: []const Item) void {
    for (num) |it| {
        switch (it) {
            .open => print("[", .{}),
            .close => print("]", .{}),
            .number => |n| print("{}", .{n}),
        }
    }
    print("\n", .{});
}

fn addNumbers(a: []const Item, b: []const Item) ![]const Item {
    //printItems(a);
    //printItems(b);

    var output = std.ArrayList(Item).init(gpa);
    errdefer output.deinit();
    try output.ensureTotalCapacity(a.len + b.len + 23);

    try output.append(.open);
    try output.appendSlice(a);
    try output.appendSlice(b);
    try output.append(.close);

    while (true) {
        var depth: usize = 0;
        var last_num: ?usize = null;
        var did_something = false;

        for (output.items) |it, i| {
            switch (it) {
                .open => {
                    depth += 1;
                    if (depth >= 5) {
                        did_something = true;
                        assert(output.items[i+1] == .number);
                        assert(output.items[i+2] == .number);
                        assert(output.items[i+3] == .close);
                        const left = output.items[i+1].number;
                        const right = output.items[i+2].number;
                        try output.replaceRange(i, 4, &[_]Item{ .{ .number = 0 } });
                        if (last_num) |idx| output.items[idx].number += left;
                        for (output.items[i+1..]) |*nxt| {
                            if (nxt.* == .number) {
                                nxt.number += right;
                                break;
                            }
                        }
                        break;
                    }
                },
                .close => {
                    depth -= 1;
                },
                .number => {
                    last_num = i;
                },
            }
        }

        if (!did_something) {
            for (output.items) |it, i| {
                if (it == .number and it.number >= 10) {
                    try output.replaceRange(i, 1, &[_]Item{
                        .open,
                        .{ .number = it.number / 2 },
                        .{ .number = (it.number + 1) / 2},
                        .close,
                    });
                    did_something = true;
                    break;
                }
            }
        }

        //printItems(simplified.items);

        if (!did_something) break;
    }

    //print("\n", .{});

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
