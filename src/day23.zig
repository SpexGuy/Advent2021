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

const State = struct {
    halls: [7]Crab = [_]Crab{ .none } ** 7,
    slots: [4][4]Crab,

    pub fn isSolved(self: State) bool {
        for (self.halls) |c| if (c != .none) return false;
        for (self.slots) |slot, i| {
            for (slot) |c| if (c.target() != i) return false;
        }
        return true;
    }

    pub fn isHallClear(self: @This(), slot: usize, hallpos: usize) bool {
        const right = 2 + slot;
        if (right < hallpos) {
            var start = right;
            while (start < hallpos) : (start += 1) {
                if (self.halls[start] != .none) return false;
            }
        }
        const left = 1+slot;
        if (hallpos < left) {
            var start = hallpos + 1;
            while (start <= left) : (start += 1) {
                if (self.halls[start] != .none) return false;
            }
        }
        return true;
    }

    pub fn printout(self: @This()) void {
        print("{c}{c}.{c}.{c}.{c}.{c}{c}\n  {c} {c} {c} {c}\n  {c} {c} {c} {c}\n",
            .{
                self.halls[0].char(), self.halls[1].char(), self.halls[2].char(), self.halls[3].char(),
                self.halls[4].char(), self.halls[5].char(), self.halls[6].char(),
                self.slots[0][3].char(), self.slots[1][3].char(), self.slots[2][3].char(), self.slots[3][3].char(),
                self.slots[0][2].char(), self.slots[1][2].char(), self.slots[2][2].char(), self.slots[3][2].char(),
                self.slots[0][1].char(), self.slots[1][1].char(), self.slots[2][1].char(), self.slots[3][1].char(),
                self.slots[0][0].char(), self.slots[1][0].char(), self.slots[2][0].char(), self.slots[3][0].char(),
            },
        );
    }
};

const hallway_costs = [4][7]u32{
    .{ 3, 2, 2, 4, 6, 8, 9 },
    .{ 5, 4, 2, 2, 4, 6, 7 },
    .{ 7, 6, 4, 2, 2, 4, 5 },
    .{ 9, 8, 6, 4, 2, 2, 3 },
};

const Crab = enum {
    none, a, b, c, d,

    pub fn cost(self: @This()) u32 {
        return ([_]u32{ 0, 1, 10, 100, 1000 })[@enumToInt(self)];
    }

    pub fn target(self: @This()) usize {
        return @enumToInt(self) - 1;
    }

    pub fn char(self: @This()) u8 {
        return ".ABCD"[@enumToInt(self)];
    }
};

const QueueEnt = struct {
    state: State,
    cost: u32,

    pub fn order(_: void, a: @This(), b: @This()) std.math.Order {
        return std.math.order(a.cost, b.cost);
    }
};

const Queue = std.PriorityDequeue(QueueEnt, void, QueueEnt.order);

pub fn main() !void {
    var timer = try std.time.Timer.start();

    //#############
    //#...........#
    //###B#B#C#D###
    //  #D#A#A#C#
    //  #########

    const part1 = try findBestSolution(.{ .slots = .{
        .{ .a, .a, .d, .b },
        .{ .b, .b, .a, .b },
        .{ .c, .c, .a, .c },
        .{ .d, .d, .c, .d },
    }});

    const p1_time = timer.lap();

    const part2 = try findBestSolution(.{ .slots = .{
        .{ .d, .d, .d, .b },
        .{ .a, .b, .c, .b },
        .{ .a, .a, .b, .c },
        .{ .c, .c, .a, .d },
    }});

    const p2_time = timer.lap();

    print("part1={}, part2={}\n", .{part1, part2});
    print("Times: part1={}, part2={}, total={}\n", .{p1_time, p2_time, p1_time + p2_time});
}

fn findBestSolution(initial_state: State) !u32 {
    var costs = Map(State, u32).init(gpa);
    defer costs.deinit();

    var q = Queue.init(gpa, {});
    defer q.deinit();

    try q.add(QueueEnt{ .state = initial_state, .cost = 0 });
    try costs.put(initial_state, 0);

    return while (q.removeMinOrNull()) |it| {
        const state = it.state;
        if (state.isSolved()) return it.cost;

        const actual_cost = costs.get(state).?;
        if (it.cost > actual_cost) continue;

        //print("\n\n{}:\n", .{it.cost});
        //it.state.printout();

        for (state.halls) |crab, pos| {
            if (crab != .none) {
                const target = crab.target();
                if (state.isHallClear(target, pos)) {
                    for (state.slots[target]) |c, i| {
                        if (c != crab) { 
                            if (c == .none) {
                                var pred = it;
                                pred.state.slots[target][i] = crab;
                                pred.state.halls[pos] = .none;
                                //pred.state.printout();
                                const distance = hallway_costs[target][pos] + @intCast(u32, state.slots[target].len - 1 - i);
                                pred.cost += distance * crab.cost();
                                const gop = try costs.getOrPut(pred.state);
                                if (!gop.found_existing or gop.value_ptr.* > pred.cost) {
                                    gop.value_ptr.* = pred.cost;
                                    try q.add(pred);
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }

        for (state.slots) |slot, idx| {
            for (slot) |c| {
                if (c != .none and c.target() != idx) break;
            } else continue;

            var self_cost: u32 = 0;

            var self_idx: usize = slot.len;
            while (self_idx > 0) : (self_cost += 1) {
                self_idx -= 1;
                const self = slot[self_idx];
                if (self != .none) {
                    for (state.halls) |c, hi| {
                        if (c == .none) {
                            if (state.isHallClear(idx, hi)) {
                                const distance = hallway_costs[idx][hi] + self_cost;
                                var pred = it;
                                pred.state.halls[hi] = slot[self_idx];
                                pred.state.slots[idx][self_idx] = .none;
                                //pred.state.printout();
                                pred.cost += distance * slot[self_idx].cost();
                                const gop = try costs.getOrPut(pred.state);
                                if (!gop.found_existing or gop.value_ptr.* > pred.cost) {
                                    gop.value_ptr.* = pred.cost;
                                    try q.add(pred);
                                } else {
                                    //print("pred state has worse cost\n", .{});
                                }
                            } else {
                                //print("hall not clear from slot {} to {}\n", .{idx, hi});
                            }
                        }
                    }
                    break;
                }
            }
        }
    } else return error.NoSolutionExists;
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
