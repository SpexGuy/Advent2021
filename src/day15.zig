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

const data = @embedFile("../data/day15.txt");

const Coord = [2]u16;

const PriorityEntry = struct {
    pos: Coord,
    cost: u64,

    pub fn compare(_: void, a: @This(), b: @This()) std.math.Order {
        return std.math.order(a.cost, b.cost);
    }
};

const Queue = std.PriorityDequeue(PriorityEntry, void, PriorityEntry.compare);

fn wrap(val: u8) u8 {
    if (val <= 9) return val;
    var v2 = val;
    while (true) {
        v2 -= 9;
        if (v2 <= 9) return v2;
    }
}

pub fn main() !void {
    var width: usize = 0;
    var height: usize = 0;
    const grid = blk: {
        var recs = List(u8).init(gpa);
        errdefer recs.deinit();
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) { continue; }
            if (width == 0) {
                width = line.len;
            } else {
                assert(line.len == width);
            }
            try recs.ensureUnusedCapacity(line.len);
            for (line) |c| {
                recs.appendAssumeCapacity(c - '0');
            }
            height += 1;
        }

        break :blk recs.toOwnedSlice();
    };
    defer gpa.free(grid);

    const pitch = width;
    const start = 0;
    
    var timer = try std.time.Timer.start();
    const part1 = blk: {
        const costs = try gpa.alloc(u64, grid.len);
        defer gpa.free(costs);
        std.mem.set(u64, costs, std.math.maxInt(u64));
        costs[0] = 0;

        var queue = Queue.init(gpa, {});
        defer queue.deinit();
        try queue.add(.{ .pos = .{0, 0}, .cost = costs[0] });
        while (true) {
            const item = queue.removeMin();
            const index = item.pos[1] * pitch + item.pos[0] + start;
            if (index == grid.len - 1) {
                break :blk item.cost;
            }
            if (costs[index] != item.cost) { continue; }

            if (item.pos[0] > 0) {
                if (item.cost + grid[index-1] < costs[index-1]) {
                    costs[index-1] = item.cost + grid[index-1];
                    try queue.add(.{ .pos = .{ item.pos[0] - 1, item.pos[1] }, .cost = costs[index-1] });
                }
            }
            if (item.pos[0] + 1 < width) {
                if (item.cost + grid[index+1] < costs[index+1]) {
                    costs[index+1] = item.cost + grid[index+1];
                    try queue.add(.{ .pos = .{ item.pos[0] + 1, item.pos[1] }, .cost = costs[index+1] });
                }
            }
            if (item.pos[1] > 0) {
                if (item.cost + grid[index-pitch] < costs[index-pitch]) {
                    costs[index-pitch] = item.cost + grid[index-pitch];
                    try queue.add(.{ .pos = .{ item.pos[0], item.pos[1] - 1 }, .cost = costs[index-pitch] });
                }
            }
            if (item.pos[1] + 1 < height) {
                if (item.cost + grid[index+pitch] < costs[index+pitch]) {
                    costs[index+pitch] = item.cost + grid[index+pitch];
                    try queue.add(.{ .pos = .{ item.pos[0], item.pos[1] + 1 }, .cost = costs[index+pitch] });
                }
            }
        }
    };

    const tp1 = timer.lap();

    const part2 = blk: {
        const costs = try gpa.alloc(u64, grid.len * 5 * 5);
        defer gpa.free(costs);
        std.mem.set(u64, costs, std.math.maxInt(u64));
        costs[0] = 0;

        var queue = Queue.init(gpa, {});
        defer queue.deinit();
        try queue.add(.{ .pos = .{0, 0}, .cost = costs[0] });

        while (true) {
            const item = queue.removeMin();
            {
                const cost_idx = item.pos[1] * pitch * 5 + item.pos[0] + start;
                if (cost_idx == costs.len - 1) {
                    break :blk item.cost;
                }
                if (costs[cost_idx] != item.cost) { continue; }
            }

            var neighbors = std.BoundedArray(Coord, 4).init(0) catch unreachable;
            if (item.pos[0] > 0) {
                neighbors.append(.{item.pos[0] - 1, item.pos[1]}) catch unreachable;
            }
            if (item.pos[0] + 1 < width*5) {
                neighbors.append(.{item.pos[0] + 1, item.pos[1]}) catch unreachable;
            }
            if (item.pos[1] > 0) {
                neighbors.append(.{item.pos[0], item.pos[1] - 1}) catch unreachable;
            }
            if (item.pos[1] + 1 < height*5) {
                neighbors.append(.{item.pos[0], item.pos[1] + 1}) catch unreachable;
            }

            for (neighbors.constSlice()) |n| {
                const grid_x = n[0] % width;
                const cell_x = n[0] / width;
                const grid_y = n[1] % height;
                const cell_y = n[1] / height;
                const grid_idx = grid_y * pitch + grid_x + start;
                const cost_idx = n[1] * pitch * 5 + n[0] + start;
                const cost_off = @intCast(u8, cell_x + cell_y);
                const grid_cost = wrap(grid[grid_idx] + cost_off);
                if (item.cost + grid_cost < costs[cost_idx]) {
                    costs[cost_idx] = item.cost + grid_cost;
                    try queue.add(.{ .pos = n, .cost = costs[cost_idx] });
                }
            }
        }
    };

    const tp2 = timer.read();

    print("part1={}, part2={}\n", .{part1, part2});
    print("tp1={}, tp2={}\n", .{tp1, tp2});
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
