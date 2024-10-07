const C = @import("../c.zig").C;

const Health = @import("../components/health.zig").Health;
const Index = @import("../components/index.zig").Index;
const Sprite = @import("../components/sprite.zig").Sprite;
const Position = @import("../components/position.zig").Position;

pub const Player = struct {
    health: Health,
    index: Index,
    position: Position,
    sprite: Sprite,
    mana: i32,
    max_mana: i32,

    pub fn init(
        health: Health,
        index: Index,
        scale: f32,
    ) Player {
        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 0,
            .width = 32.0,
            .height = 32.0,
        };

        return .{
            .health = health,
            .index = index,
            .position = .{ .x = 0, .y = 0 },
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
            .mana = 2,
            .max_mana = 3,
        };
    }
};
