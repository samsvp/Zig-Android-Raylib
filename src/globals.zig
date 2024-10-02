const C = @import("c.zig").C;

const Board = @import("systems/board.zig").Board;
const Input = @import("systems/input.zig").Input;
const PlayerCards = @import("systems/player_deck.zig").PlayerCards;

pub const Globals = struct {
    sprite_sheet: C.Texture2D,
    cards_sprite_sheet: C.Texture2D,

    player_cards: *PlayerCards,
    board: *Board,
    input: *Input,
};
