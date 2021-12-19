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

const data = @embedFile("../data/day19.txt");

const P3 = struct {
    x: int, y: int, z: int,

    pub fn add(self: @This(), b: @This()) @This() {
        const result = P3{
            .x = self.x + b.x,
            .y = self.y + b.y,
            .z = self.z + b.z,
        };
        return result;
    }

    pub fn sub(self: @This(), b: @This()) @This() {
        const result = P3{
            .x = self.x - b.x,
            .y = self.y - b.y,
            .z = self.z - b.z,
        };
        return result;
    }

    pub fn rotate(self: @This(), rotation: u32) P3 {
        const x = self.x;
        const y = self.y;
        const z = self.z;
        const result = switch (rotation) {
             0 => P3{ .x =  x, .y =  y, .z =  z },
             1 => P3{ .x =  x, .y =  z, .z = -y },
             2 => P3{ .x =  x, .y = -y, .z = -z },
             3 => P3{ .x =  x, .y = -z, .z =  y },
 
             4 => P3{ .x = -x, .y =  y, .z = -z },
             5 => P3{ .x = -x, .y =  z, .z =  y },
             6 => P3{ .x = -x, .y = -y, .z =  z },
             7 => P3{ .x = -x, .y = -z, .z = -y },
 
             8 => P3{ .x =  y, .y = -x, .z =  z },
             9 => P3{ .x =  y, .y = -z, .z = -x },
            10 => P3{ .x =  y, .y =  x, .z = -z },
            11 => P3{ .x =  y, .y =  z, .z =  x },
 
            12 => P3{ .x = -y, .y = -x, .z = -z },
            13 => P3{ .x = -y, .y = -z, .z =  x },
            14 => P3{ .x = -y, .y =  x, .z =  z },
            15 => P3{ .x = -y, .y =  z, .z = -x },

            16 => P3{ .x =  z, .y =  x, .z =  y },
            17 => P3{ .x =  z, .y =  y, .z = -x },
            18 => P3{ .x =  z, .y = -x, .z = -y },
            19 => P3{ .x =  z, .y = -y, .z =  x },

            20 => P3{ .x = -z, .y =  x, .z = -y },
            21 => P3{ .x = -z, .y =  y, .z =  x },
            22 => P3{ .x = -z, .y = -x, .z =  y },
            23 => P3{ .x = -z, .y = -y, .z = -x },

            else => unreachable,
        };
        return result;
    }

    pub fn cross(a: P3, b: P3) P3 {
        const result = P3{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
        return result;
    }

    pub fn eql(a: P3, b: P3) bool {
        return a.x == b.x and a.y == b.y and a.z == b.z;
    }
};

test "rotations" {
    var rot: u32 = 0;
    var any_failed = false;
    while (rot < 24) : (rot += 1) {
        const x = P3{ .x = 1, .y = 0, .z = 0 };
        const y = P3{ .x = 0, .y = 1, .z = 0 };
        const z = P3{ .x = 0, .y = 0, .z = 1 };
        const rx = x.rotate(rot);
        const ry = y.rotate(rot);
        const rz = z.rotate(rot);
        if (!rx.cross(ry).eql(rz)) {
            print("\nwrong: {}\n", .{rot});
            any_failed = true;
        }
    }
    if (any_failed) unreachable;
}

const Scanner = struct {
    beacons: []const P3,
};

const ScanMap = struct {
    placed: std.DynamicBitSet,
    rotations: []u32,
    positions: []P3,
    known_beacons: std.AutoArrayHashMap(P3, void),

    pub fn init(count: usize) !ScanMap {
        return ScanMap{
            .placed = try std.DynamicBitSet.initFull(gpa, count),
            .rotations = try gpa.alloc(u32, count),
            .positions = try gpa.alloc(P3, count),
            .known_beacons = std.AutoArrayHashMap(P3, void).init(gpa),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.known_beacons.deinit();
        gpa.free(self.positions);
        gpa.free(self.rotations);
        self.placed.deinit();
        self.* = undefined;
    }

    pub fn add(self: *@This(), scanner: Scanner, rotation: u32, position: P3, index: usize) void {
        self.placed.unset(index);
        self.rotations[index] = rotation;
        self.positions[index] = position;
        for (scanner.beacons) |be| {
            self.known_beacons.put(be.rotate(rotation).add(position), {}) catch unreachable;
        }
    }
};

pub fn main() !void {
    var timer = try std.time.Timer.start();
    var recs = blk: {
        var lines = tokenize(u8, data, "\r\n");
        var beacons = std.ArrayList(Scanner).init(gpa);
        errdefer beacons.deinit();
        var points = std.ArrayList(P3).init(gpa);
        defer points.deinit();
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }

            if (line[1] == '-') {
                if (points.items.len > 0) {
                    const items = points.toOwnedSlice();
                    try beacons.append(.{ .beacons = items });
                }
                continue;
            }

            var parts = split(u8, line, ",");
            try points.append(.{
                .x = parseInt(int, parts.next().?, 10) catch unreachable,
                .y = parseInt(int, parts.next().?, 10) catch unreachable,
                .z = parseInt(int, parts.next().?, 10) catch unreachable,
            });
            assert(parts.next() == null);
        }
        if (points.items.len > 0) {
            const items = points.toOwnedSlice();
            try beacons.append(.{ .beacons = items });
        }
        break :blk beacons.toOwnedSlice();
    };
    defer gpa.free(recs);

    const parse_time = timer.lap();

    var count_table = Map(P3, u8).init(gpa);
    defer count_table.deinit();

    var maps = try ScanMap.init(recs.len);
    defer maps.deinit();

    maps.add(recs[0], 0, .{.x = 0, .y = 0, .z = 0}, 0);
    placed: while (maps.placed.count() != 0) {
        var it = maps.placed.iterator(.{});
        while (it.next()) |idx| {
            const scanner = recs[idx];
            var rotation: u32 = 0;
            while (rotation < 24) : (rotation += 1) {
                count_table.clearRetainingCapacity();
                for (maps.known_beacons.keys()) |ank_raw| {
                    for (scanner.beacons) |ank_be| {
                        const scanner_pos = ank_raw.sub(ank_be.rotate(rotation));
                        const entry = try count_table.getOrPut(scanner_pos);
                        if (entry.found_existing) {
                            entry.value_ptr.* += 1;
                            if (entry.value_ptr.* >= 12) {
                                //print("Scanner {} @{},{},{}\n", .{idx, scanner_pos.x, scanner_pos.y, scanner_pos.z});
                                maps.add(scanner, rotation, scanner_pos, idx);
                                continue :placed;
                            }
                        } else {
                            entry.value_ptr.* = 1;
                        }
                    }
                }
            }
        }
        unreachable;
    }
    const part1 = maps.known_beacons.count();

    const part1_time = timer.lap();

    var part2: int = 0;
    for (maps.positions[0..maps.positions.len-1]) |p0, i| {
        for (maps.positions[i+1..]) |p1| {
            const delta = p0.sub(p1);
            const manh =
                (std.math.absInt(delta.x) catch unreachable) +
                (std.math.absInt(delta.y) catch unreachable) +
                (std.math.absInt(delta.z) catch unreachable);
            if (manh > part2) part2 = manh;
        }
    }

    const part2_time = timer.read();

    print("part1={}, part2={}\n", .{part1, part2});
    print("Timing: parse={}, part1={}, part2={}, total={}\n", .{parse_time, part1_time, part2_time, parse_time + part1_time + part2_time});
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
