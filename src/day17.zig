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

const target_min_x = 240;
const target_max_x = 292;
const target_min_y = -90;
const target_max_y = -57;

pub fn main() !void {
    // Maximum initial y velocity is that for which
    // we barely hit the bottom of the target.
    // Since speed is symmetric, speed down as we cross
    // the y axis is equal to speed up when we launched.
    assert(target_min_y < 0);
    const max_init_y = -target_min_y - 1;

    var timer = try std.time.Timer.start();

    const part1 = triangle(max_init_y);

    _ = hitsTarget(9, 3);

    var part2: int = 0;
    var y: int = target_min_y;
    while (y <= max_init_y) : (y += 1) {
        var x: int = 1;
        while (x <= target_max_x) : (x += 1) {
            if (hitsTarget(x, y)) {
                part2 += 1;
            }
        }
    }

    const time = timer.read();

    print("part1={}, part2={}, time={}\n", .{part1, part2, time});
}

fn triangle(i: int) int {
    return @divExact(i * (i+1), 2);
}

fn hitsTarget(init_x: int, init_y: int) bool {
    var dx = init_x;
    var dy = init_y;
    var x: int = 0;
    var y: int = 0;

    // Take advantage of y being symmetrical
    // We can fast forward to the point where the ball
    // falls back down below the y=0 line.
    if (init_y >= 0) {
        const steps_to_cross_x_axis = 2 * init_y + 1;
        if (init_x <= steps_to_cross_x_axis) {
            dx = 0;
            x = triangle(init_x);
            if (x < target_min_x or x > target_max_x) return false;
        } else {
            dx = init_x - steps_to_cross_x_axis;
            x = triangle(init_x) - triangle(dx);
            if (x > target_max_x) return false;
        }
        dy = -init_y - 1;
    }

    while (dx > 0) {
        x += dx;
        y += dy;
        dx -= 1;
        dy -= 1;

        if (@boolToInt(x > target_max_x) | @boolToInt(y < target_min_y) != 0) {
            // missed the target, we're under it
            return false;
        }

        if (@boolToInt(x >= target_min_x) & @boolToInt(y <= target_max_y) != 0) {
            //print("hit! {}, {}\n", .{init_x, init_y});
            return true;
        }
    }

    if (x < target_min_x or x > target_max_x) {
        return false;
    }

    while (true) {
        y += dy;
        dy -= 1;
        if (y <= target_max_y) {
            return y >= target_min_y;
        }
    }
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
