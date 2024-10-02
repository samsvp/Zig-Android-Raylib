const std = @import("std");

const C = @import("../c.zig").C;
const Sprite = @import("../components/sprite.zig").Sprite;

pub const CardKinds = enum {
    tower,
    queen,
    king,
    pawn,
    bishop,
    knight,
};

pub const Card = struct {
    sprite: Sprite,
    card_kind: CardKinds,

    pub fn init(
        scale: f32,
        card_kind: CardKinds,
    ) Card {
        const pos = switch (card_kind) {
            .king => C.Vector2{ .x = 0, .y = 0 },
            .queen => C.Vector2{ .x = 48.0, .y = 0 },
            .bishop => C.Vector2{ .x = 48.0 * 2.0, .y = 0 },
            .tower => C.Vector2{ .x = 48.0 * 3.0, .y = 0 },
            .knight => C.Vector2{ .x = 48 * 4, .y = 0 },
            .pawn => C.Vector2{ .x = 48.0 * 5, .y = 0 },
        };
        const frame_rect = C.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = 48.0,
            .height = 64.0,
        };

        return .{
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
            .card_kind = card_kind,
        };
    }
};

pub const Deck = std.ArrayList(Card);
pub const Hand = std.ArrayList(Card);
pub const Graveyard = std.ArrayList(Card);
