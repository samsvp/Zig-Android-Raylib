const C = @import("c.zig").C;

const Board = @import("systems/board.zig").Board;
const Input = @import("systems/input.zig").Input;
const PlayerCards = @import("systems/player_deck.zig").PlayerCards;
const CoroutineRunner = @import("systems/coroutine.zig").CoroutineRunner;
const Turn = @import("systems/turn.zig").Turn;

pub const Globals = struct {
    window_w: c_int,
    window_h: c_int,

    sprite_sheet: C.Texture2D,
    cards_sprite_sheet: C.Texture2D,

    turn: *Turn,

    player_cards: *PlayerCards,
    board: *Board,
    input: *Input,
    coroutine_runner: *CoroutineRunner,
};
