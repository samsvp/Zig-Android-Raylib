const C = @import("../c.zig").C;

const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

pub const initial_w = 800;
pub const initial_h = 450;

pub fn render(
    window_w: c_int,
    window_h: c_int,
    texture: C.Texture,
    position: Position,
    sprite: Sprite,
) void {
    const fw: f32 = @floatFromInt(window_w - initial_w);
    const fh: f32 = @floatFromInt(window_h - initial_h);
    const dest_rect = C.Rectangle{
        .x = position.x + 0.5 * fw,
        .y = position.y + 0.5 * fh,
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
