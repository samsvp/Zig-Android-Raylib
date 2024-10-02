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
        .width = sprite.frame_rect.width * sprite.scale,
        .height = sprite.frame_rect.height * sprite.scale,
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
