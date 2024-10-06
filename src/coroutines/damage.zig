const C = @import("../c.zig").C;
const std = @import("std");

const Board = @import("../systems/board.zig").Board;
const Character = @import("../systems/board.zig").Character;
const Input = @import("../systems/input.zig").Input;
const Random = @import("../systems/random.zig").Random;
const render = @import("../systems/render.zig").render;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

const N = 75;

pub const DamageCoroutine = struct {
    texture: C.Texture,
    blood_scales: [N]f32,
    frame_rect: C.Rectangle,

    pos: [N]Position,
    vel: [N]C.Vector2,
    acc: [N]C.Vector2,
    lifetime: f32 = 0.0,
    max_lifetime: f32,
    char: Character,
    damage: i32,
    health: i32 = 1,

    board: *Board,

    pub fn init(
        texture: C.Texture,
        board: *Board,
        index: Index,
        char: Character,
        damage: i32,
    ) DamageCoroutine {
        var pos0 = board.posFromIndex(index) orelse Position{ .x = 0, .y = 0 };
        pos0.x += 16;
        pos0.y += 16;

        var pos: [N]Position = undefined;
        var vel: [N]C.Vector2 = undefined;
        var acc: [N]C.Vector2 = undefined;
        var blood_scales: [N]f32 = undefined;

        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 96.0,
            .width = 32.0,
            .height = 32.0,
        };

        for (0..N) |i| {
            pos[i] = pos0;

            const vx = Random.floatInRange(-200.0, 200.0);
            const vy = Random.floatInRange(-200.0, 200.0);
            vel[i] = .{ .x = vx, .y = vy };

            const s = Random.floatInRange(0.2, 1.0);
            blood_scales[i] = s;

            acc[i] = .{
                .x = -s * 2.5,
                .y = -s * 2.5,
            };
        }

        return .{
            .texture = texture,
            .blood_scales = blood_scales,
            .frame_rect = frame_rect,

            .board = board,

            .pos = pos,
            .vel = vel,
            .acc = acc,
            .max_lifetime = 1.5,

            .char = char,
            .damage = damage,
        };
    }

    pub fn coroutine(self: *DamageCoroutine, dt: f32) bool {
        if (self.lifetime == 0) {
            switch (self.char) {
                inline else => |*c| {
                    c.*.health -= self.damage;
                    if (c.*.health <= 0) {
                        c.*.health = 0;
                    }
                    self.health = c.*.health;
                },
            }
        }

        if (self.health <= 0) for (0..self.pos.len) |i| {
            if (self.lifetime < self.max_lifetime) {
                const old_vel = self.vel[i];

                self.vel[i].x += self.acc[i].x * old_vel.x * dt;
                self.vel[i].y += self.acc[i].y * old_vel.y * dt;

                self.pos[i].x += (self.vel[i].x + old_vel.x) / 2.0 * dt;
                self.pos[i].y += (self.vel[i].y + old_vel.y) / 2.0 * dt;
            }

            const mod = i % 3;
            render(
                self.texture,
                self.pos[i],
                .{
                    .scale = self.blood_scales[i],
                    .frame_rect = self.frame_rect,
                    .tint = .{
                        .r = 255 * @as(u8, @intFromBool(mod == 0)),
                        .g = 255 * @as(u8, @intFromBool(mod == 1)),
                        .b = 255 * @as(u8, @intFromBool(mod == 2)),
                        .a = @intFromFloat(255.0 * (1.0 - self.lifetime / self.max_lifetime)),
                    },
                },
            );
        };

        if (self.lifetime < self.max_lifetime) {
            self.lifetime += dt;
        } else {
            return true;
        }

        if (self.lifetime <= 0.5) {
            if (@mod(std.math.round(self.lifetime * 10.0), 2.0) == 0) {
                switch (self.char) {
                    inline else => |*c| c.*.sprite.tint = C.RED,
                }
            }
        }

        return false;
    }
};
