const std = @import("std");
const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Sprite = @import("../components/sprite.zig").Sprite;

const Tile = @import("tile.zig").Tile;

const Board = @import("../systems/board.zig").Board;

const MovementFunc = *const fn (
    *Board,
    Index,
    std.mem.Allocator,
) std.ArrayList(*Tile);

pub const Card = struct {
    sprite: Sprite,
    movementFunc: MovementFunc,

    pub fn init(
        scale: f32,
        movementFunc: MovementFunc,
    ) Card {
        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 0,
            .width = 48.0,
            .height = 64.0,
        };

        return .{
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
            .movementFunc = movementFunc,
        };
    }
};

pub const Deck = std.ArrayList(Card);
pub const Hand = std.ArrayList(Card);
pub const Graveyard = std.ArrayList(Card);
