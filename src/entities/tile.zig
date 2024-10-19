const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

pub fn posFromVec2(p: C.Vector2, offset: Position, scale: f32) Position {
    return .{
        .x = p.x * 32.0 * scale + offset.x,
        .y = p.y * 32.0 * scale + offset.y,
    };
}

pub const Tile = struct {
    index: Index,
    pos: Position,
    sprite: Sprite,

    pub fn init(index: Index, offset: Position, scale: f32) Tile {
        const frame_rect = if ((index.x + index.y) % 2 == 0)
            C.Rectangle{
                .x = 64.0,
                .y = 96.0,
                .width = 32.0,
                .height = 32.0,
            }
        else
            C.Rectangle{
                .x = 96.0,
                .y = 96.0,
                .width = 32.0,
                .height = 32.0,
            };

        const p = C.Vector2{
            .x = @floatFromInt(index.x),
            .y = @floatFromInt(index.y),
        };

        return .{
            .index = index,
            .pos = posFromVec2(p, offset, scale),
            .sprite = .{
                .scale = scale,
                .frame_rect = frame_rect,
                .tint = C.WHITE,
            },
        };
    }
};
