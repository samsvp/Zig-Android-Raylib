const C = @import("../c.zig").C;

const Random = @import("../systems/random.zig").Random;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

pub const TreeColor = enum {
    GREEN,
    YELLOW,
    RED,
    PURPLE,
};

pub const Tree = struct {
    tree_sprite: Sprite,
    floor_sprite: Sprite,
    pos: Position,

    pub fn init(pos: Position, tree_color: TreeColor, tint: C.Color, scale: f32) Tree {
        const x: f32 = @floatFromInt(Random.int(c_int, 0, 4));
        const y: f32 = switch (tree_color) {
            .GREEN => 0,
            .PURPLE => 1,
            .RED => 2,
            .YELLOW => 3,
        };

        const tree_frame_rect = C.Rectangle{
            .x = x * 64.0,
            .y = y * 64.0,
            .width = 64.0,
            .height = 64.0,
        };

        const floor_frame = C.Rectangle{
            .x = 0,
            .y = y * 32.0,
            .width = 96.0,
            .height = 32.0,
        };
        return .{
            .tree_sprite = Sprite{ .scale = scale, .tint = tint, .frame_rect = tree_frame_rect },
            .floor_sprite = Sprite{ .scale = scale / 2, .tint = tint, .frame_rect = floor_frame },
            .pos = pos,
        };
    }
};
