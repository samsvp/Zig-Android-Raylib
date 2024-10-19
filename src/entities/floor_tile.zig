const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;
const posFromVec2 = @import("tile.zig").posFromVec2;

pub const FloorTile = struct {
    pos: Position,
    sprite: Sprite,

    pub fn init(index: Index, columns: u64, offset: Position, scale: f32) FloorTile {
        const frame_rect = if (index.x == 0)
            C.Rectangle{
                .x = 0.0,
                .y = 128.0,
                .width = 32.0,
                .height = 32.0,
            }
        else if (index.x == columns - 1)
            C.Rectangle{
                .x = 64.0,
                .y = 128.0,
                .width = 32.0,
                .height = 32.0,
            }
        else
            C.Rectangle{
                .x = 32.0,
                .y = 128.0,
                .width = 32.0,
                .height = 32.0,
            };

        const p = C.Vector2{
            .x = @floatFromInt(index.x),
            .y = @floatFromInt(index.y),
        };

        return .{
            .pos = posFromVec2(p, offset, scale),
            .sprite = .{
                .scale = scale,
                .frame_rect = frame_rect,
                .tint = C.WHITE,
            },
        };
    }
};
