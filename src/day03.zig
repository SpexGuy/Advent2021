const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day03.txt");

const int = i64;

const Rec = struct {
    value: int,
    dir: Kind,
};

const Kind = enum {
    down,
    up,
    forward,
};

pub fn main() !void {
    var counts: [12]u32 = std.mem.zeroes([12]u32);
    var recs = blk: {
        var list = List(u12).init(gpa);
        list.ensureTotalCapacity(1000) catch unreachable;
        var lines = tokenize(u8, data, "\n\r");
        while (lines.next()) |line| {
            if (line.len == 0) {continue;}

            const value = try parseInt(u12, line, 2);

            list.append(value) catch unreachable;

            var i: u12 = 1;
            var x: usize = 0;
            while (i != 0) : (i = i << 1) {
                counts[x] += @boolToInt(value & i != 0);
                x += 1;
            }
        }
        break :blk list.toOwnedSlice();
    };

    var gamma: u12 = 0;
    {
        var i: u12 = 1;
        var x: usize = 0;
        while (i != 0) : (i = i << 1) {
            if (counts[x] * 2 >= recs.len) {
                gamma |= i;
            }
            x += 1;
        }
    }

    const part1 = @as(usize, gamma) * @as(usize, ~gamma);
    print("part1={}\n", .{part1});
    assert(part1 == 4103154);

    const gamma_high_bit = gamma & (1<<11);

    bench(recs, part2FilteredLists, gamma_high_bit, "filtered lists");
    bench(recs, part2InPlaceFilter, gamma_high_bit, "in place filtering");
    bench(recs, part2Sorting, gamma_high_bit, "sorting");
    bench(recs, part2CountingSort, gamma_high_bit, "counting sort");
}

fn bench(recs: []const u12, comptime benchmark: anytype, gamma_high_bit: u12, name: []const u8) void {
    const scratch = gpa.alloc(u12, recs.len) catch unreachable;
    defer gpa.free(scratch);

    var i: usize = 0;
    var best_time: usize = std.math.maxInt(usize);
    var total_time: usize = 0;
    const num_runs = 10000;
    while (i < num_runs) : (i += 1) {
        @memcpy(@ptrCast([*]u8, scratch.ptr), @ptrCast([*]const u8, recs.ptr), recs.len * @sizeOf(u12));
        std.mem.doNotOptimizeAway(scratch.ptr);
        const timer = std.time.Timer.start() catch unreachable;
        @call(.{}, benchmark, .{scratch, gamma_high_bit});
        asm volatile ("" : : : "memory");
        const lap_time = timer.read();
        if (best_time > lap_time) best_time = lap_time;
        total_time += lap_time;
    }
    print("min {} avg {} {s}\n", .{best_time, total_time / num_runs, name});
}


fn part2FilteredLists(recs: []const u12, gamma_high_bit: u12) void {
    var oxygen_remain = List(u12).init(gpa);
    var co2_remain = List(u12).init(gpa);
    var next = List(u12).init(gpa);
    defer oxygen_remain.deinit();
    defer co2_remain.deinit();
    defer next.deinit();

    oxygen_remain.ensureTotalCapacity(recs.len) catch unreachable;
    co2_remain.ensureTotalCapacity(recs.len) catch unreachable;
    next.ensureTotalCapacity(recs.len) catch unreachable;

    for (recs) |item| {
        if (item & (1<<11) == gamma_high_bit) {
            oxygen_remain.appendAssumeCapacity(item);
        } else {
            co2_remain.appendAssumeCapacity(item);
        }
    }

    {
        var i: u12 = 1<<10;
        while (oxygen_remain.items.len != 1) : (i = i >> 1) {
            assert(i != 0);
            const bit_target = gammaMask(oxygen_remain.items, i) & i;

            for (oxygen_remain.items) |item| {
                if (bit_target == item & i) {
                    next.appendAssumeCapacity(item);
                }
            }

            var tmp = oxygen_remain;
            oxygen_remain = next;
            tmp.clearRetainingCapacity();
            next = tmp;
        }
    }
    const oxygen = oxygen_remain.items[0];

    {
        var mask: u12 = gamma_high_bit ^ (1<<11);
        var i: u12 = 1<<10;
        while (co2_remain.items.len != 1) : (i = i >> 1) {
            assert(i != 0);
            const bit_target = (~gammaMask(co2_remain.items, i)) & i;

            mask |= bit_target;

            for (co2_remain.items) |item| {
                if (bit_target == item & i) {
                    next.appendAssumeCapacity(item);
                }
            }

            //print("bit {x} co2 mask {x} {}/{}\n", .{i, mask, next.items.len, co2_remain.items.len});

            var tmp = co2_remain;
            co2_remain = next;
            tmp.clearRetainingCapacity();
            next = tmp;
        }
    }

    const co2 = co2_remain.items[0];

    const part2 = @as(usize, oxygen) * @as(usize, co2);
    std.mem.doNotOptimizeAway(&part2);

    // Don't use assert here because that could influence the optimizer
    if (std.debug.runtime_safety and oxygen != 3399) @panic("Bad oxygen value");
    if (std.debug.runtime_safety and co2 != 1249) @panic("Bad co2 value");
}

fn part2InPlaceFilter(recs: []const u12, gamma_high_bit: u12) void {
    var last_oxy_match: u12 = 0;
    var last_co2_match: u12 = 0;

    var i: u12 = 1<<10;
    var mask: u12 = 1<<11;
    var oxy_target: u12 = gamma_high_bit;
    var co2_target: u12 = gamma_high_bit ^ (1<<11);
    while (true) : (i = i >> 1) {
        const prev_mask = mask;
        mask |= i;

        const oxy_untarget = oxy_target | i;
        const co2_untarget = co2_target | i;

        var oxy_zero_count: usize = 0;
        var oxy_one_count: usize = 0;
        var co2_zero_count: usize = 0;
        var co2_one_count: usize = 0;
        for (recs) |it| {
            oxy_zero_count += @boolToInt(it & mask == oxy_target);
            co2_zero_count += @boolToInt(it & mask == co2_target);
            if (it & prev_mask == oxy_target) last_oxy_match = it;
            if (it & prev_mask == co2_target) last_co2_match = it;
            oxy_one_count += @boolToInt(it & mask == oxy_untarget);
            co2_one_count += @boolToInt(it & mask == co2_untarget);
        }
        oxy_target |= std.math.boolMask(u12, oxy_zero_count <= oxy_one_count) & i;
        co2_target |= std.math.boolMask(u12, co2_zero_count > co2_one_count) & i;

        const oxy_matches = if (oxy_zero_count <= oxy_one_count) oxy_one_count else oxy_zero_count;
        const co2_matches = if (co2_zero_count > co2_one_count) co2_one_count else co2_zero_count;
        //print("bit {x} co2 mask {x} {}/{}\n", .{i, co2_target, co2_matches, co2_zero_count + co2_one_count});

        // we need to do at least one pass after all bits are set to record the last co2 zero correctly
        if (@boolToInt(oxy_matches <= 1) & @boolToInt(co2_matches <= 1) != 0) break;

        assert(i != 0);
    }

    const part2 = @as(usize, last_oxy_match) * @as(usize, last_co2_match);
    std.mem.doNotOptimizeAway(&part2);

    // Don't use assert here because that could influence the optimizer
    if (std.debug.runtime_safety and last_oxy_match != 3399) @panic("Bad oxygen value");
    if (std.debug.runtime_safety and last_co2_match != 1249) @panic("Bad co2 value");
}

const Divider = struct {
    halfway_bit: u12,
    idx: usize,
};

fn findSortedDivider(recs: []const u12, bit: u12, comptime sentinel_must_exist: bool) Divider {
    var idx = recs.len/2;
    var halfway_bit = recs[idx] & bit;
    if (halfway_bit != 0) {
        while (sentinel_must_exist or idx > 0) {
            if (recs[idx-1] & bit == 0) break;
            idx -= 1;
        }
    } else {
        idx += 1;
        while (sentinel_must_exist or idx < recs.len) {
            if(recs[idx] & bit != 0) break;
            idx += 1;
        }
    }
    return .{
        .halfway_bit = halfway_bit,
        .idx = idx,
    };
}

fn part2Sorting(recs: []u12, gamma_high_bit: u12) void {
    _ = gamma_high_bit;
    sort(u12, recs, {}, comptime asc(u12));

    var oxy_min: usize = 0;
    var oxy_max: usize = recs.len;
    var co2_min: usize = 0;
    var co2_max: usize = recs.len;

    // First divider applies to both
    {
        const div = findSortedDivider(recs, 1<<11, true);
        if (div.halfway_bit == 0) {
            oxy_max = div.idx;
            co2_min = div.idx;
        } else {
            co2_max = div.idx;
            oxy_min = div.idx;
        }
    }

    // Now do co2
    {
        var i: u12 = 1<<10;
        while (co2_min + 1 != co2_max) : (i = i >> 1) {
            assert(i != 0);
            const div = findSortedDivider(recs[co2_min..co2_max], i, true);
            if (div.halfway_bit != 0) {
                co2_max = co2_min + div.idx;
            } else {
                co2_min = co2_min + div.idx;
            }
        }
    }

    // Then oxygen
    {
        var i: u12 = 1<<10;
        while (oxy_min + 1 != oxy_max) : (i = i >> 1) {
            assert(i != 0);
            const div = findSortedDivider(recs[oxy_min..oxy_max], i, false);
            if (div.halfway_bit != 0) {
                oxy_min = oxy_min + div.idx;
            } else {
                oxy_max = oxy_min + div.idx;
            }
        }
    }

    const oxy = recs[oxy_min];
    const co2 = recs[co2_min];

    const part2 = @as(usize, oxy) * @as(usize, co2);
    std.mem.doNotOptimizeAway(&part2);

    // Don't use assert here because that could influence the optimizer
    if (std.debug.runtime_safety and oxy != 3399) @panic("Bad oxygen value");
    if (std.debug.runtime_safety and co2 != 1249) @panic("Bad co2 value");
}

fn part2CountingSort(recs: []u12, gamma_high_bit: u12) void {
    _ = gamma_high_bit;

    // Sort by making a bit set and then splatting it back out
    {
        var set_values = std.StaticBitSet(1<<12).initEmpty();
        for (recs) |rec| {
            set_values.set(rec);
        }

        var it = set_values.iterator(.{});
        var i: usize = 0;
        while (it.next()) |value| : (i += 1) {
            recs[i] = @intCast(u12, value);
        }
        assert(i == recs.len);
    }

    var oxy_min: usize = 0;
    var oxy_max: usize = recs.len;
    var co2_min: usize = 0;
    var co2_max: usize = recs.len;

    // First divider applies to both
    {
        const div = findSortedDivider(recs, 1<<11, true);
        if (div.halfway_bit == 0) {
            oxy_max = div.idx;
            co2_min = div.idx;
        } else {
            co2_max = div.idx;
            oxy_min = div.idx;
        }
    }

    // Now do co2
    {
        var i: u12 = 1<<10;
        while (co2_min + 1 != co2_max) : (i = i >> 1) {
            assert(i != 0);
            const div = findSortedDivider(recs[co2_min..co2_max], i, true);
            if (div.halfway_bit != 0) {
                co2_max = co2_min + div.idx;
            } else {
                co2_min = co2_min + div.idx;
            }
        }
    }

    // Then oxygen
    {
        var i: u12 = 1<<10;
        while (oxy_min + 1 != oxy_max) : (i = i >> 1) {
            assert(i != 0);
            const div = findSortedDivider(recs[oxy_min..oxy_max], i, false);
            if (div.halfway_bit != 0) {
                oxy_min = oxy_min + div.idx;
            } else {
                oxy_max = oxy_min + div.idx;
            }
        }
    }

    const oxy = recs[oxy_min];
    const co2 = recs[co2_min];

    const part2 = @as(usize, oxy) * @as(usize, co2);
    std.mem.doNotOptimizeAway(&part2);

    // Don't use assert here because that could influence the optimizer
    if (std.debug.runtime_safety and oxy != 3399) @panic("Bad oxygen value");
    if (std.debug.runtime_safety and co2 != 1249) @panic("Bad co2 value");
}

fn gammaMask(items: []const u12, bit: u12) u12 {
    var count: usize = 0;
    for (items) |it| {
        count += @boolToInt(it & bit != 0);
    }
    return std.math.boolMask(u12, count * 2 >= items.len);
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
