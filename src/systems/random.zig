/// System to create random numbers without choosing the same number
/// many times. Weights are adapted such that, on the first call,
/// all values have the same weight. When the first number is chosen,
/// its weight is divided between the remaining options and set
/// to 0. The process then repeats on each call.
/// The time and space cost to generate a random number is O(N).
const std = @import("std");
const random = std.rand.DefaultPrng;

/// Will panic if array is empty
fn binarySearch(array: []f32, target: f32) usize {
    var left: usize = 0;
    var right: usize = array.len - 1;
    var middle: usize = 0;

    // check special cases
    if (target <= array[left]) return left;
    if (target >= array[right]) return right;

    while (true) {
        middle = (left + right) / 2;
        const a = array[middle];

        if (a < target) {
            left = middle + 1;
        } else if (a > target) {
            if (target >= array[middle - 1]) break;

            right = middle - 1;
        } else {
            middle += 1;
            break;
        }

        if (left >= right) {
            middle += 1;
            break;
        }
    }
    return middle;
}

pub const Random = struct {
    rand: std.Random.Xoshiro256,
    // cumulative weights
    weights: std.ArrayList(f32),

    pub fn init(
        length: usize,
        allocator: std.mem.Allocator,
        seed: ?u64,
    ) !Random {
        if (length < 2) {
            return error.LengthTooShort;
        }

        const rand = if (seed) |s|
            random.init(s)
        else
            random.init(@intCast(std.time.timestamp()));

        const f_length: f32 = @floatFromInt(length);
        const w = 1.0 / f_length;
        var weights = try std.ArrayList(f32).initCapacity(allocator, length);
        for (0..length) |i| {
            const f_i: f32 = @floatFromInt(i + 1);
            weights.appendAssumeCapacity(f_i * w);
        }

        return .{
            .rand = rand,
            .weights = weights,
        };
    }

    pub fn deinit(self: *Random) void {
        self.weights.deinit();
    }

    pub fn generate(self: *Random) usize {
        const r = self.rand.random().float(f32);
        const index = binarySearch(self.weights.items, r);
        const f_length: f32 = @floatFromInt(self.weights.items.len - 1);
        var weights = self.weights.items;
        const w_add = if (index != 0)
            (weights[index] - weights[index - 1]) / f_length
        else
            weights[index] / f_length;

        var old_w = weights[0];
        weights[0] = if (index == 0) 0 else weights[0] + w_add;
        for (1..weights.len - 1) |i| {
            if (i == index) {
                old_w = weights[i];
                weights[i] = weights[i - 1];
                continue;
            }

            const d = weights[i] - old_w;
            old_w = weights[i];
            weights[i] = weights[i - 1] + d + w_add;
        }
        return index;
    }
};

test "binary search" {
    var arr = [_]f32{ 0.1, 0.25, 0.32, 0.32, 0.7, 0.74, 0.8, 0.94, 1.0 };

    const target0 = 0.32;
    var m = binarySearch(&arr, target0);
    try std.testing.expectEqual(4, m);

    const target1 = 0.3;
    m = binarySearch(&arr, target1);
    try std.testing.expectEqual(2, m);

    const target3 = 0.0;
    m = binarySearch(&arr, target3);
    try std.testing.expectEqual(0, m);

    const target2 = 1.0;
    m = binarySearch(&arr, target2);
    try std.testing.expectEqual(arr.len - 1, m);

    const target4 = 0.75;
    m = binarySearch(&arr, target4);
    try std.testing.expectEqual(6, m);

    const target5 = 0.7;
    m = binarySearch(&arr, target5);
    try std.testing.expectEqual(5, m);

    const target6 = 0.95;
    m = binarySearch(&arr, target6);
    try std.testing.expectEqual(arr.len - 1, m);

    const target7 = 0.2;
    m = binarySearch(&arr, target7);
    try std.testing.expectEqual(1, m);

    const target8 = 0.05;
    m = binarySearch(&arr, target8);
    try std.testing.expectEqual(0, m);

    const target9 = 0.82;
    m = binarySearch(&arr, target9);
    try std.testing.expectEqual(7, m);
}

test "generate" {
    const printWeights = struct {
        fn printWeights(ws: []f32) void {
            for (ws) |w| {
                std.debug.print("{d},", .{w});
            }
            std.debug.print("\n", .{});
        }
    }.printWeights;

    const allocator = std.testing.allocator;
    var rand = try Random.init(4, allocator, 0);
    defer rand.deinit();
    std.debug.print("{}: ", .{0});
    printWeights(rand.weights.items);
    for (0..10) |i| {
        const index = rand.generate();
        std.debug.print("{}, {}: ", .{ i + 1, index });
        printWeights(rand.weights.items);
    }
}
