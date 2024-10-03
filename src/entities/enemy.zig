const std = @import("std");
const C = @import("../c.zig").C;

// components
const Index = @import("../components/index.zig").Index;
const Health = @import("../components/health.zig").Health;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

const Tile = @import("tile.zig").Tile;
const Board = @import("../systems/board.zig").Board;

const MovementFunc = *const fn (
    *Board,
    Index,
    std.mem.Allocator,
) std.ArrayList(*Tile);

pub const Enemy = struct {
    health: Health,
    index: Index,
    position: Position,
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
            .position = .{ .x = 0, .y = 0 },
            .movementFunc = movementFunc,
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
        };
    }
};
