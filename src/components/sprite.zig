const C = @import("../c.zig").C;

pub const Sprite = struct {
    scale: f32,
    frame_rect: C.Rectangle,
    tint: C.Color,
};
