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

const data = @embedFile("../data/day12.txt");

const Edge = struct {
    a: u8,
    b: u8,
};

const start_id = 0;
const end_id = 1;

pub fn main() !void {
    var edges: []const Edge = undefined;
    var names: []const Str = undefined;
    {
        var cave_ids = StrMap(u8).init(gpa);
        defer cave_ids.deinit();
        var cave_names = List(Str).init(gpa);
        errdefer cave_names.deinit();
        var edges_l = List(Edge).init(gpa);
        errdefer edges_l.deinit();

        try cave_ids.put("start", start_id);
        try cave_ids.put("end", end_id);
        try cave_names.append("start");
        try cave_names.append("end");
        var next_cave_id: u8 = 2; // after start and end id

        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            var parts = split(u8, line, "-");
            const a = parts.next().?;
            const b = parts.next().?;
            assert(parts.next() == null);

            const a_id = cave_ids.get(a) orelse blk: {
                const id = next_cave_id;
                next_cave_id += 1;
                try cave_ids.put(a, id);
                try cave_names.append(a);
                break :blk id;
            };
            const b_id = cave_ids.get(b) orelse blk: {
                const id = next_cave_id;
                next_cave_id += 1;
                try cave_ids.put(b, id);
                try cave_names.append(b);
                break :blk id;
            };

            try edges_l.append(.{ .a = a_id, .b = b_id });
        }
        
        edges = edges_l.toOwnedSlice();
        names = cave_names.toOwnedSlice();
    }
    defer gpa.free(edges);
    defer gpa.free(names);

    const part1_r = try countPathsRecursive(names, edges, false);
    const part2_r = try countPathsRecursive(names, edges, true);
    const part1_s = try countPathsStack(names, edges, false);
    const part2_s = try countPathsStack(names, edges, true);

    print("recur: part1={}, part2={}\n", .{part1_r, part2_r});
    print("stack: part1={}, part2={}\n", .{part1_s, part2_s});
}

fn countPathsRecursive(names: []const Str, edges: []const Edge, in_allow_revisit: bool) !usize {
    const Walk = struct {
        already_hit: std.DynamicBitSet,
        names: []const Str,
        edges: []const Edge,

        fn countPaths(self: *@This(), id: u8, allow_revisit: bool) usize {
            if (id == end_id) return 1;

            var is_double = false;
            if (self.already_hit.isSet(id)) {
                if (!allow_revisit or id == start_id) return 0;
                is_double = true;
            } else if (self.names[id][0] >= 'a') {
                self.already_hit.set(id);
            }
            defer if (!is_double) {
                self.already_hit.unset(id);
            };

            var paths: usize = 0;
            next_edge: for (self.edges) |edge| {
                const n = if (edge.a == id) edge.b
                else if (edge.b == id) edge.a
                else continue :next_edge;

                paths += self.countPaths(n, allow_revisit and !is_double);
            }

            return paths;
        }
    };

    var walk = Walk{
        .edges = edges,
        .names = names,
        .already_hit = try std.DynamicBitSet.initEmpty(gpa, names.len),
    };
    defer walk.already_hit.deinit();

    return walk.countPaths(start_id, in_allow_revisit);
}

fn countPathsStack(names: []const Str, edges: []const Edge, allow_revisit: bool) !usize {
    const State = struct {
        id: u8,
        next_edge: u8 = 0,
        is_double: bool,
    };

    var stack = std.ArrayList(State).init(gpa);
    defer stack.deinit();

    var already_hit = try std.DynamicBitSet.initEmpty(gpa, names.len);
    defer already_hit.deinit();

    already_hit.set(start_id);
    try stack.append(.{
        .id = start_id,
        .is_double = false,
    });

    var total: usize = 0;
    var did_double = false;

    loop: while (stack.items.len > 0) {
        const curr = &stack.items[stack.items.len - 1];
        next_edge: while (curr.next_edge < edges.len) {
            const e = edges[curr.next_edge];
            curr.next_edge += 1;

            const n = if (e.a == curr.id) e.b
            else if (e.b == curr.id) e.a
            else continue :next_edge;

            // never move back to the start
            if (n == start_id) {
                continue :next_edge;
            }

            if (n == end_id) {
                total += 1;
                continue :next_edge;
            }

            var is_double: bool = false;
            if (already_hit.isSet(n)) {
                if (!allow_revisit or did_double) {
                    continue :next_edge;
                }
                did_double = true;
                is_double = true;
            } else {
                const is_small = names[n][0] >= 'a';
                if (is_small) already_hit.set(n);
            }

            try stack.append(.{
                .id = n,
                .is_double = is_double,
            });
            continue :loop;
        }

        if (curr.is_double) {
            did_double = false;
        } else {
            already_hit.unset(curr.id);
        }
        _ = stack.pop();
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
