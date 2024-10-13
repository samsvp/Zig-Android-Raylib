const C = @import("../c.zig").C;
const Position = @import("../components/position.zig").Position;
const Random = @import("random.zig").Random;
const Sprite = @import("../components/sprite.zig").Sprite;

const render = @import("render.zig").render;

const MAX_SIZE = 8;

pub const Clouds = struct {
    cloud_buffer: [MAX_SIZE]Position = undefined,
    cloud_scales: [MAX_SIZE]f32 = undefined,
    len: usize = 0,
    sprite: Sprite,
    cloud_texture: C.Texture,
    countdown: f32 = 0,
    spawn_time: f32 = 3.0,

    pub fn addCloud(self: *Clouds, ifw: f32, ifh: f32) void {
        self.cloud_buffer[self.len] = .{
            .x = -0.4 * ifw,
            .y = Random.floatInRange(0.1 * ifh, 0.9 * ifh),
        };
        self.cloud_scales[self.len] = Random.floatInRange(0.5, 1.5);
        self.spawn_time = 3 * Random.floatInRange(0.8, 1.2);
        self.len += 1;
    }

    pub fn update(
        self: *Clouds,
        window_w: c_int,
        window_h: c_int,
        init_window_w: c_int,
        init_window_h: c_int,
        dt: f32,
    ) void {
        const fw: f32 = @floatFromInt(window_w);
        const ifw: f32 = @floatFromInt(init_window_w);
        const ifh: f32 = @floatFromInt(init_window_h);
        if (self.len == 0) {
            self.addCloud(ifw, ifh);
        } else if (self.len < MAX_SIZE) {
            self.countdown += dt;
            if (self.countdown > self.spawn_time) {
                self.addCloud(ifw, ifh);
                self.countdown = 0;
            }
        }

        for (0..self.len) |i| {
            const position = &self.cloud_buffer[i];
            const scale = self.cloud_scales[i];
            position.*.x += 50.0 * (3.0 - scale) * dt;

            render(
                window_w,
                window_h,
                self.cloud_texture,
                position.*,
                Sprite{
                    .scale = self.sprite.scale * self.cloud_scales[i],
                    .frame_rect = self.sprite.frame_rect,
                    .tint = .{
                        .r = 255,
                        .g = 255,
                        .b = 255,
                        .a = @intFromFloat(255.0 * (scale) / 1.5),
                    },
                },
            );
        }

        // remove offscreen clouds
        var i: usize = self.len;
        while (i > 0) {
            i -= 1;
            const position = self.cloud_buffer[i];
            if (position.x < 1.1 * fw) {
                continue;
            }
            self.cloud_buffer[i] = self.cloud_buffer[self.len - 1];
            self.cloud_scales[i] = self.cloud_scales[self.len - 1];
            self.len -= 1;
        }
    }
};
