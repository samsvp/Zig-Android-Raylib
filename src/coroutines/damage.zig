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

fn pointBoxCollision(point: Position, rect: C.Rectangle) bool {
    return rect.x <= point.x and
        rect.x + rect.width >= point.x and
        rect.y <= point.y and
        rect.y + rect.height >= point.y;
}

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

            const vx = Random.floatInRange(-50.0, 50.0);
            const vy = Random.floatInRange(-50.0, 50.0);
            vel[i] = .{ .x = vx, .y = vy };
            acc[i] = .{
                .x = -Random.floatInRange(1.0, 2.0),
                .y = -Random.floatInRange(1.0, 2.0),
            };

            blood_scales[i] = Random.floatInRange(0.2, 1.0);
        }

        return .{
            .texture = texture,
            .blood_scales = blood_scales,
            .frame_rect = frame_rect,

            .board = board,

            .pos = pos,
            .vel = vel,
            .acc = acc,
            .max_lifetime = 3.0,

            .char = char,
            .damage = damage,
        };
    }

    pub fn coroutine(self: *DamageCoroutine, dt: f32) bool {
        if (self.lifetime == 0) {
            switch (self.char) {
                inline else => |*c| {
                    c.*.health -= self.damage;
                    if (c.*.health < 0) {
                        c.*.health = 0;
                    }
                },
            }
        }

        const b0 = self.board.posFromIndex(.{ .x = 0, .y = 0 }).?;
        const fr: f32 = @floatFromInt(self.board.rows);
        const fc: f32 = @floatFromInt(self.board.columns);
        const rect = C.Rectangle{
            .x = b0.x - 8.0,
            .y = b0.y - 8.0,
            .width = fc * 32.0 * 1.5,
            .height = fr * 32.0 * 1.5,
        };
        for (0..self.pos.len) |i| {
            if (self.lifetime < self.max_lifetime) {
                const old_vel = self.vel[i];

                self.vel[i].x += self.acc[i].x * old_vel.x * dt;
                self.vel[i].y += self.acc[i].y * old_vel.y * dt;

                self.pos[i].x += (self.vel[i].x + old_vel.x) / 2.0 * dt;
                self.pos[i].y += (self.vel[i].y + old_vel.y) / 2.0 * dt;
            }

            if (pointBoxCollision(self.pos[i], rect))
                render(
                    self.texture,
                    self.pos[i],
                    .{
                        .scale = self.blood_scales[i],
                        .frame_rect = self.frame_rect,
                        .tint = C.WHITE,
                    },
                );
        }
        if (self.lifetime < self.max_lifetime) {
            self.lifetime += dt;
        }

        return false;
    }
};
