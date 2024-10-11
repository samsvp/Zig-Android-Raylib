const C = @import("../c.zig").C;

const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

pub const initial_w = 800;
pub const initial_h = 450;

pub fn calcScale(
    window_w: c_int,
    window_h: c_int,
) C.Vector2 {
    const f_init_w: f32 = @floatFromInt(initial_w);
    const f_init_h: f32 = @floatFromInt(initial_h);
    const fw: f32 = @floatFromInt(window_w);
    const fh: f32 = @floatFromInt(window_h);
    const scale_x = fw / f_init_w;
    const scale_y = fh / f_init_h;
    return .{ .x = scale_x, .y = scale_y };
}

pub fn render(
    window_w: c_int,
    window_h: c_int,
    texture: C.Texture,
    position: Position,
    sprite: Sprite,
) void {
    // calc scale
    const scale = calcScale(window_w, window_h);
    // render
    const dest_rect = C.Rectangle{
        .x = (position.x) * scale.x,
        .y = (position.y) * scale.y,
        .width = sprite.frame_rect.width * sprite.scale * scale.x,
        .height = sprite.frame_rect.height * sprite.scale * scale.y,
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
