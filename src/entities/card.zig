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
        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 0,
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
