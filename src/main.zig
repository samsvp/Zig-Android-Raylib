const std = @import("std");

const C = @import("c.zig").C;
const exit = @import("utils.zig").exit;
const Save = @import("save.zig");
const Movement = @import("movement.zig");

const AI = @import("systems/AI.zig").AI;
const Board = @import("systems/board.zig").Board;
const Input = @import("systems/input.zig").Input;
const render = @import("systems/render.zig").render;
const Coroutine = @import("systems/coroutine.zig");
const Turn = @import("systems/turn.zig");

const Enemy = @import("entities/enemy.zig").Enemy;
const PlayerCards = @import("systems/player_deck.zig").PlayerCards;

const Position = @import("components/position.zig").Position;
const Sprite = @import("components/sprite.zig").Sprite;
const Globals = @import("globals.zig").Globals;

fn pointBoxCollision(point: Position, rect: C.Rectangle) bool {
    return rect.x <= point.x and
        rect.x + rect.width >= point.x and
        rect.y <= point.y and
        rect.y + rect.height >= point.y;
}

pub export fn main() void {
    const window_w = 800;
    const window_h = 450;
    C.InitWindow(window_w, window_h, "raylib [core] example - basic window");
    defer C.CloseWindow();

    // load all assets
    // save everything into assets
    _ = C.ChangeDirectory("assets");

    const sprite_sheet = C.LoadTexture("sprites.png");
    defer C.UnloadTexture(sprite_sheet);
    if (sprite_sheet.id <= 0) {
        exit("FILEIO: Could not load spritesheet");
    }

    const cards_sprite_sheet = C.LoadTexture("card-sprites.png");
    defer C.UnloadTexture(cards_sprite_sheet);
    if (sprite_sheet.id <= 0) {
        exit("FILEIO: Could not load cards spritesheet");
    }

    var player_cards = PlayerCards.init(0, 1.5, "base_deck.txt", std.heap.c_allocator);
    defer player_cards.deinit();

    _ = C.ChangeDirectory("..");
    // end load assets

    player_cards.draw(3);
    std.debug.print("hand len: {}\n", .{player_cards.hand.items.len});

    const board_pos = Position{ .x = 400.0 - 1.5 * 4.0 * 32.0, .y = 450.0 / 16.0 };
    var board = Board.init(8, 6, board_pos, std.heap.c_allocator) catch {
        exit("BOARD: could not create board, OOM");
        unreachable;
    };
    defer board.deinit();
    board.spawnEnemies(7, 1) catch exit("BOARD: could not spawn enemies, OOM");
    var input = Input{};

    var turn = Turn.Turn{ .current = 1, .player_kind = Turn.PlayerKind.PLAYER };

    Coroutine.global_runner = Coroutine.CoroutineRunner.init(std.heap.c_allocator);
    defer Coroutine.global_runner.deinit();

    var end_turn_button_pos = Position{
        .x = 0.68 * 800.0,
        .y = 0.90 * 450.0,
    };

    var end_turn_button_sprite = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 96.0,
            .y = 128.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    var back_sprite_pos = Position{
        .x = 0.68 * 800.0,
        .y = 0.82 * 450.0,
    };

    var back_sprite = Sprite{
        .scale = 1.5,
        .tint = C.WHITE,
        .frame_rect = C.Rectangle{
            .x = 64.0,
            .y = 128.0,
            .width = 32.0,
            .height = 32.0,
        },
    };

    var globals = Globals{
        .window_w = window_w,
        .window_h = window_h,

        .back_button = &back_sprite,
        .back_button_position = &back_sprite_pos,

        .end_button = &end_turn_button_sprite,
        .end_button_position = &end_turn_button_pos,

        .sprite_sheet = sprite_sheet,
        .cards_sprite_sheet = cards_sprite_sheet,
        .turn = &turn,
        .board = &board,
        .player_cards = &player_cards,
        .input = &input,
        .coroutine_runner = &Coroutine.global_runner,
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

    // const score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    // const hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    var current_enemy_idx: usize = 0;
    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        if (C.IsKeyPressed(C.KEY_A)) {
            //AI.chooseMoves(0, &globals);
            if (C.IsWindowFullscreen()) {
                globals.window_w = window_w;
                globals.window_h = window_h;
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

        for (board.tiles.items) |tile| {
            render(
                globals.window_w,
                globals.window_h,
                sprite_sheet,
                tile.pos,
                tile.sprite,
            );
        }
        if (board.player) |*player| {
            player.sprite.tint = C.WHITE;
        }

        const dt = C.GetFrameTime();
        Coroutine.global_runner.update(dt);
        globals.input.update(dt);

        for (board.enemies.items) |e| {
            board.previewMoves(e.*, sprite_sheet, globals.window_w, globals.window_h);
        }

        if (globals.player_cards.selected_card > -1) {
            render(
                globals.window_w,
                globals.window_h,
                sprite_sheet,
                back_sprite_pos,
                back_sprite,
            );
        }

        render(
            globals.window_w,
            globals.window_h,
            sprite_sheet,
            end_turn_button_pos,
            end_turn_button_sprite,
        );

        for (board.enemies.items) |e| {
            if (e.health <= 0) continue;

            const pos = board.posFromIndex(e.index) orelse e.position;
            render(
                globals.window_w,
                globals.window_h,
                sprite_sheet,
                pos,
                e.sprite,
            );
        }

        if (board.player) |player| if (player.health > 0) {
            const pos = board.posFromIndex(player.index) orelse player.position;
            render(
                globals.window_w,
                globals.window_h,
                sprite_sheet,
                pos,
                player.sprite,
            );

            for (0..@intCast(player.health)) |i| {
                const heart_pos = Position{
                    .x = @floatFromInt(16 * i + window_w / 4),
                    .y = @floatFromInt(2 * window_h / 3 + 22),
                };
                render(
                    globals.window_w,
                    globals.window_h,
                    sprite_sheet,
                    heart_pos,
                    heart_sprite,
                );
            }

            if (turn.player_kind == Turn.PlayerKind.PLAYER) for (0..@intCast(player.mana)) |i| {
                const mana_pos = Position{
                    .x = @floatFromInt(16 * i + 2 * window_w / 3),
                    .y = @floatFromInt(2 * window_h / 3 + 22),
                };
                render(
                    globals.window_w,
                    globals.window_h,
                    sprite_sheet,
                    mana_pos,
                    mana_sprite,
                );
            };
            if (turn.player_kind == Turn.PlayerKind.PLAYER) for (player_cards.hand.items, 0..) |card, i| {
                render(
                    globals.window_w,
                    globals.window_h,
                    cards_sprite_sheet,
                    player_cards.getHandPosition(i),
                    card.sprite,
                );
            };
        };

        if (turn.player_kind == Turn.PlayerKind.COMP) {
            if (globals.input.lock_ > 0) {
                continue;
            }

            if (current_enemy_idx >= globals.board.enemies.items.len) {
                globals.turn.change(&globals);
                current_enemy_idx = 0;
                continue;
            }

            AI.chooseMoves(current_enemy_idx, &globals);
            current_enemy_idx += 1;
        }
        input.listen(&globals);
    }
}
