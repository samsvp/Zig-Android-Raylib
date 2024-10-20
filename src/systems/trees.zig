const std = @import("std");

const C = @import("../c.zig").C;

const R = @import("random.zig");
const Random = @import("random.zig").Random;
const Tree = @import("../entities/tree.zig").Tree;
const TreeColor = @import("../entities/tree.zig").TreeColor;
const render = @import("render.zig").render;

fn sortTrees(_: void, t1: Tree, t2: Tree) bool {
    return t1.tree_sprite.scale < t2.tree_sprite.scale;
}

pub const Trees = struct {
    trees: std.ArrayList(Tree),
    t: f32 = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        window_width: c_int,
        window_height: c_int,
        n: usize,
        color: TreeColor,
    ) !Trees {
        var trees = try std.ArrayList(Tree).initCapacity(allocator, n);
        const fw: f32 = @floatFromInt(window_width);
        const fh: f32 = @floatFromInt(window_height);
        var res_left = try R.poissonSample2D(
            std.heap.c_allocator,
            n / 2,
            0.0 * fw,
            0.1 * fh,
            0.2 * fw,
            0.8 * fh,
        );
        defer res_left.deinit();
        var res_right = try R.poissonSample2D(
            std.heap.c_allocator,
            n / 2,
            0.7 * fw,
            0.1 * fh,
            0.9 * fw,
            0.8 * fh,
        );
        defer res_right.deinit();

        for (0..n) |i| {
            const p = if (i < n / 2)
                res_left.items[i]
            else
                res_right.items[i - n / 2];
            const scale: f32 = Random.floatInRange(0.5, 1.5);
            const s = scale / 1.5;
            const v: u8 = @intFromFloat(255 * s * s);
            const tint = C.Color{ .r = v, .g = v, .b = v, .a = 255 };

            const tree = Tree.init(.{ .x = p.x, .y = p.y }, color, tint, scale);
            trees.appendAssumeCapacity(tree);
        }
        std.mem.sort(Tree, trees.items, {}, sortTrees);

        return .{ .trees = trees };
    }

    pub fn update(
        self: *Trees,
        window_w: c_int,
        window_h: c_int,
        tree_texture: C.Texture,
        floor_texture: C.Texture,
        dt: f32,
    ) void {
        self.t += dt;
        for (self.trees.items) |tree| {
            const offset = 5.0 * tree.tree_sprite.scale;
            const A = tree.tree_sprite.scale;
            const tree_pos = C.Vector2{
                .x = tree.pos.x,
                .y = tree.pos.y + 2.0 * A * A * @sin(2.0 * (self.t + offset)),
            };
            render(window_w, window_h, tree_texture, tree_pos, tree.tree_sprite);
            const tree_rect = tree.tree_sprite.frame_rect;
            const floor_pos = .{
                .x = tree_pos.x + tree_rect.width * tree.tree_sprite.scale / 8,
                .y = tree_pos.y + tree_rect.height * tree.tree_sprite.scale,
            };
            render(window_w, window_h, floor_texture, floor_pos, tree.floor_sprite);
        }
    }

    pub fn deinit(self: *Trees) void {
        self.trees.deinit();
    }
};
