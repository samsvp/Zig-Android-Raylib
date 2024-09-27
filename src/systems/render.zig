const C = @import("../c.zig").C;

const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

pub fn render(
    texture: C.Texture,
    position: Position,
    sprite: Sprite,
) void {
    const dest_rect = C.Rectangle{
        .x = position.x,
        .y = position.y,
        .width = 32.0 * sprite.scale,
        .height = 32.0 * sprite.scale,
    };

    C.DrawTexturePro(
        texture,
        sprite.frame_rect,
        dest_rect,
        .{ .x = 0.0, .y = 0.0 },
        0.0,
        sprite.tint,
    );
}
