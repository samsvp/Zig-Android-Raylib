const C = @import("../c.zig").C;

// components
const Index = @import("../components/index.zig").Index;
const Health = @import("../components/health.zig").Health;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

const MovementFunc = @import("../movement.zig").MovementFunc;

pub const Enemy = struct {
    health: Health,
    index: Index,
    movementFunc: MovementFunc,
    sprite: Sprite,

    pub fn init(
        health: Health,
        spriteIndex: Index,
        scale: f32,
        movementFunc: MovementFunc,
    ) Enemy {
        const p = Position{
            .x = @floatFromInt(spriteIndex.x),
            .y = @floatFromInt(spriteIndex.y),
        };
        const frame_rect = C.Rectangle{
            .x = p.x * 32.0,
            .y = p.y * 32.0,
            .width = 32.0,
            .height = 32.0,
        };

        return .{
            .health = health,
            .index = .{ .x = 0, .y = 0 },
            .movementFunc = movementFunc,
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
        };
    }
};
