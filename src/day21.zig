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

// Input values
const p1_init = 7;
const p2_init = 5;

/// Possible total values from three dice, and
/// number of universes where each total can happen.
const rolls  = [_]u32{ 3, 4, 5, 6, 7, 8, 9 };
const counts = [_]u64{ 1, 3, 6, 7, 6, 3, 1 };

const Table = struct {
    /// Playing to 21, the max number of turns is 10, plus 1 for turn 0
    const max_turns = 11;

    /// Number of universes where the player has not won after this many turns
    alive: [max_turns]u64 = std.mem.zeroes([max_turns]u64),

    /// Number of universes where the player wins on this turn
    wins: [max_turns]u64 = std.mem.zeroes([max_turns]u64),

    fn countRecursive(self: *@This(), depth: u32, alive: u64, pos: u32, score: u32) void {
        for (rolls) |r, i| {
            const new_pos = (pos + r) % 10;
            const new_score = score + new_pos + 1;
            const new_alive = alive * counts[i];
            if (new_score >= 21) {
                self.wins[depth] += new_alive;
            } else {
                self.alive[depth] += new_alive;
                self.countRecursive(depth + 1, new_alive, new_pos, new_score);
            }
        }
    }

    pub fn buildRecursive(self: *@This(), start_pos: u32) void {
        self.alive[0] = 1;
        self.wins[0] = 0;
        self.countRecursive(1, 1, start_pos - 1, 0);
    }

    const Buffer = [21][10]u64;

    pub fn buildIterative(self: *@This(), start_pos: u32) void {
        var pos = start_pos - 1;

        // [score][position-1]
        var buf_a: Buffer = undefined;
        var buf_b: Buffer = undefined;

        @memset(@ptrCast([*]u8, &buf_a), 0, @sizeOf(Buffer));
        buf_a[0][pos] = 1;
        self.alive[0] = 1;
        self.wins[0] = 0;

        var turn: usize = 1;
        while (turn < max_turns-1) : (turn += 2) {
            self.countTurn(turn, &buf_a, &buf_b);
            self.countTurn(turn + 1, &buf_b, &buf_a);
        }
        if (turn < max_turns) {
            self.countTurn(turn, &buf_a, &buf_b);
        }
    }

    fn countTurn(noalias self: *@This(), turn: usize, noalias curr: *const Buffer, noalias next: *Buffer) void {
        @memset(@ptrCast([*]u8, next), 0, @sizeOf(Buffer));
        var alive_this_turn: u64 = 0;
        var wins_this_turn: u64 = 0;
        var score: usize = 0;
        while (score < 21) : (score += 1) {
            var pos: usize = 0;
            while (pos < 10) : (pos += 1) {
                const universes = curr[score][pos];
                for (rolls) |r, i| {
                    const new_pos = (pos + r) % 10;
                    const new_score = score + new_pos + 1;
                    const new_universes = universes * counts[i];
                    if (new_score < 21) {
                        next[new_score][new_pos] += new_universes;
                        alive_this_turn += new_universes;
                    } else {
                        wins_this_turn += new_universes;
                    }
                }
            }
        }
        self.alive[turn] = alive_this_turn;
        self.wins[turn] = wins_this_turn;
    }
};

pub fn main() !void {
    var timer = try std.time.Timer.start();

    const part1 = blk: {
        var p1: u32 = p1_init - 1;
        var p2: u32 = p2_init - 1;

        var p1_score: u32 = 0;
        var p2_score: u32 = 0;

        var turn: u32 = 0;
        var die: u32 = 0;
        const loser_score = while (true) {
            {
                turn += 1;
                const roll = 3*die + 6;
                die += 3;
                p1 = (p1 + roll) % 10;
                p1_score += (p1 + 1);
                if (p1_score >= 1000) break p2_score;
            }
            {
                turn += 1;
                const roll = 3*die + 6;
                die += 3;
                p2 = (p2 + roll) % 10;
                p2_score += (p2 + 1);
                if (p2_score >= 1000) break p1_score;
            }
        } else unreachable;

        break :blk @as(u64, loser_score) * die;
    };

    const p1_time = timer.lap();

    var p1_table = Table{};
    //p1_table.buildRecursive(p1_init);
    p1_table.buildIterative(p1_init);

    var p2_table = Table{};
    //p2_table.buildRecursive(p2_init);
    p2_table.buildIterative(p2_init);

    var p1_wins: u64 = 0;
    var p2_wins: u64 = 0;
    // Calculate wins by multiplying the number of universes where we win
    // by the number of unverses where the opponent had not already won.
    // Note the off by one for p1 because p1 plays first.
    for (p1_table.wins[1..]) |wins, turn| {
        p1_wins += wins * p2_table.alive[turn];
    }
    for (p2_table.wins) |wins, turn| {
        p2_wins += wins * p1_table.alive[turn];
    }
    const part2 = max(p1_wins, p2_wins);

    const p2_time = timer.lap();

    print("part1={}, part2={}\n", .{part1, part2});
    print("Times: part1={}, part2={}, total={}\n", .{p1_time, p2_time, p1_time + p2_time});
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
