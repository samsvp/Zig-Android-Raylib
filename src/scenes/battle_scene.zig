const std = @import("std");

const C = @import("../c.zig").C;

const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;
const AI = @import("../systems/AI.zig").AI;
const Board = @import("../systems/board.zig").Board;
const Character = @import("../systems/board.zig").Character;
const Input = @import("../systems/input.zig").Input;
const Turn = @import("../systems/turn.zig");
const Coroutine = @import("../systems/coroutine.zig");
const CoroutineRunner = @import("../systems/coroutine.zig").CoroutineRunner;

const PlayerCards = @import("../systems/player_deck.zig").PlayerCards;

const exit = @import("../utils.zig").exit;
const render = @import("../systems/render.zig").render;

pub const BattleGlobals = struct {
    init_window_w: c_int,
    init_window_h: c_int,

    window_w: c_int,
    window_h: c_int,

    sprite_sheet: C.Texture2D,
    pieces_sheet: C.Texture,
    cards_sprite_sheet: C.Texture2D,

    heart_sprite: Sprite,
    mana_sprite: Sprite,

    back_button: *Sprite,
    back_button_position: Position,

    end_button: *Sprite,
    end_button_position: Position,

    turn: *Turn.Turn,

    player_cards: *PlayerCards,
    board: *Board,
    input: *Input,
    coroutine_runner: *CoroutineRunner,

    allocator: std.mem.Allocator,
    current_enemy_idx: usize = 0,
};

pub fn init(
    window_w: c_int,
    window_h: c_int,
    board_w: usize,
    board_h: usize,
    enemy_amount: usize,
    queens_amount: usize,
    allocator: std.mem.Allocator,
    sprite_sheet: C.Texture,
    pieces_sheet: C.Texture,
    cards_sprite_sheet: C.Texture,
    player_cards: *PlayerCards,
) !*BattleGlobals {
    player_cards.draw(3);
    std.debug.print("hand len: {}\n", .{player_cards.hand.items.len});

    const board_pos = Position{ .x = 400.0 - 1.5 * 4.0 * 32.0, .y = 450.0 / 16.0 };
    var board = try allocator.create(Board);
    board.* = Board.init(board_w, board_h, board_pos, std.heap.c_allocator) catch {
        exit("BOARD: could not create board, OOM");
        unreachable;
    };
    board.spawnEnemies(enemy_amount, queens_amount) catch exit(
        "BOARD: could not spawn enemies, OOM",
    );
    const input = try allocator.create(Input);
    input.* = Input{};

    const turn = try allocator.create(Turn.Turn);
    turn.* = Turn.Turn{ .current = 1, .player_kind = Turn.PlayerKind.PLAYER };

    Coroutine.global_runner = Coroutine.CoroutineRunner.init(std.heap.c_allocator);

    const end_turn_button_pos = Position{
        .x = 0.68 * 800.0,
        .y = 0.90 * 450.0,
    };

    const end_turn_button_sprite = try allocator.create(Sprite);
    end_turn_button_sprite.* = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 96.0,
            .y = 128.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    const back_sprite_pos = Position{
        .x = 0.68 * 800.0,
        .y = 0.82 * 450.0,
    };

    const back_sprite = try allocator.create(Sprite);
    back_sprite.* = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 64.0,
            .y = 128.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    const mana_sprite = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 32.0,
            .y = 96.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    const heart_sprite = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 0.0,
            .y = 128.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    const bg = try allocator.create(BattleGlobals);
    bg.* = BattleGlobals{
        .init_window_w = window_w,
        .init_window_h = window_h,

        .window_w = window_w,
        .window_h = window_h,

        .heart_sprite = heart_sprite,
        .mana_sprite = mana_sprite,

        .back_button = back_sprite,
        .back_button_position = back_sprite_pos,

        .end_button = end_turn_button_sprite,
        .end_button_position = end_turn_button_pos,

        .sprite_sheet = sprite_sheet,
        .pieces_sheet = pieces_sheet,
        .cards_sprite_sheet = cards_sprite_sheet,
        .turn = turn,
        .board = board,
        .player_cards = player_cards,
        .input = input,
        .coroutine_runner = &Coroutine.global_runner,

        .allocator = allocator,
    };

    return bg;
}

pub fn deinit(bg: *BattleGlobals) void {
    bg.allocator.destroy(bg.turn);
    bg.allocator.destroy(bg.board);
    bg.allocator.destroy(bg.input);
    bg.allocator.destroy(bg.back_button);
    bg.allocator.destroy(bg.end_button);
}

fn sortCharacters(_: void, c1: Character, c2: Character) bool {
    const y1 = switch (c1) {
        inline else => |c| c.index.y,
    };
    const y2 = switch (c2) {
        inline else => |c| c.index.y,
    };
    return y1 < y2;
}

pub fn update(globals: *BattleGlobals, dt: f32) void {
    // Update
    //----------------------------------------------------------------------------------
    if (C.IsKeyPressed(C.KEY_A)) {
        //AI.chooseMoves(0, &globals);
        if (C.IsWindowFullscreen()) {
            globals.window_w = globals.init_window_w;
            globals.window_h = globals.init_window_h;
        } else {
            const display = C.GetCurrentMonitor();
            // if we are not full screen, set the window size to match the monitor we are on
            globals.window_w = C.GetMonitorWidth(display);
            globals.window_h = C.GetMonitorHeight(display);
        }
        C.SetWindowSize(globals.window_w, globals.window_h);
        C.ToggleFullscreen();
    }

    C.BeginDrawing();
    defer C.EndDrawing();

    C.ClearBackground(C.BLACK);

    const board = globals.board;
    const turn = globals.turn;
    const w: usize = @intCast(globals.init_window_w);
    const h: usize = @intCast(globals.init_window_h);

    for (board.tiles.items) |tile| {
        render(
            globals.window_w,
            globals.window_h,
            globals.sprite_sheet,
            tile.pos,
            tile.sprite,
        );
    }
    if (board.player) |*player| {
        player.sprite.tint = C.WHITE;
    }

    Coroutine.global_runner.update(dt);
    globals.input.update(dt);

    for (board.enemies.items) |e| {
        board.previewMoves(
            e.*,
            globals.sprite_sheet,
            globals.window_w,
            globals.window_h,
            C.WHITE,
        );
    }

    if (globals.player_cards.selected_card > -1) {
        render(
            globals.window_w,
            globals.window_h,
            globals.sprite_sheet,
            globals.back_button_position,
            globals.back_button.*,
        );
    }

    render(
        globals.window_w,
        globals.window_h,
        globals.sprite_sheet,
        globals.end_button_position,
        globals.end_button.*,
    );

    var characters_to_draw = std.ArrayList(Character).initCapacity(
        std.heap.c_allocator,
        board.enemies.items.len + 1,
    ) catch unreachable;
    defer characters_to_draw.deinit();
    for (board.enemies.items) |e| {
        characters_to_draw.appendAssumeCapacity(.{ .enemy = e });
    }
    if (board.player) |*p| {
        characters_to_draw.appendAssumeCapacity(.{ .player = p });
    }

    std.mem.sort(Character, characters_to_draw.items, {}, sortCharacters);
    for (characters_to_draw.items) |char| {
        switch (char) {
            inline else => |c| {
                if (c.health <= 0) continue;

                var pos = board.posFromIndex(c.index) orelse c.position;
                pos.x += 4.0;
                pos.y -= 24.0;
                render(
                    globals.window_w,
                    globals.window_h,
                    globals.pieces_sheet,
                    pos,
                    c.sprite,
                );
            },
        }
    }

    if (board.player) |player| if (player.health > 0) {
        for (0..@intCast(player.health)) |i| {
            const heart_pos = Position{
                .x = @floatFromInt(16 * i + w / 4),
                .y = @floatFromInt(2 * h / 3 + 22),
            };
            render(
                globals.window_w,
                globals.window_h,
                globals.sprite_sheet,
                heart_pos,
                globals.heart_sprite,
            );
        }

        if (turn.player_kind == Turn.PlayerKind.PLAYER) for (0..@intCast(player.mana)) |i| {
            const mana_pos = Position{
                .x = @floatFromInt(16 * i + 2 * w / 3),
                .y = @floatFromInt(2 * h / 3 + 22),
            };
            render(
                globals.window_w,
                globals.window_h,
                globals.sprite_sheet,
                mana_pos,
                globals.mana_sprite,
            );
        };
        if (turn.player_kind == Turn.PlayerKind.PLAYER) {
            for (globals.player_cards.hand.items, 0..) |card, i| {
                render(
                    globals.window_w,
                    globals.window_h,
                    globals.cards_sprite_sheet,
                    globals.player_cards.getHandPosition(i),
                    card.sprite,
                );
            }
        }
    };

    if (turn.player_kind == Turn.PlayerKind.COMP) {
        if (globals.input.lock_ > 0) {
            return;
        }

        if (globals.current_enemy_idx >= globals.board.enemies.items.len) {
            globals.turn.change(globals);
            globals.*.current_enemy_idx = 0;
            return;
        }

        AI.chooseMoves(globals.current_enemy_idx, globals);
        globals.*.current_enemy_idx += 1;
    }
    globals.input.listen(globals);
}
