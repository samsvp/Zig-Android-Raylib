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

const Enemy = @import("entities/enemy.zig").Enemy;
const PlayerCards = @import("systems/player_deck.zig").PlayerCards;

const Position = @import("components/position.zig").Position;
const Globals = @import("globals.zig").Globals;

pub export fn main() void {
    C.InitWindow(800, 450, "raylib [core] example - basic window");
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

    Coroutine.global_runner = Coroutine.CoroutineRunner.init(std.heap.c_allocator);
    defer Coroutine.global_runner.deinit();

    var globals = Globals{
        .sprite_sheet = sprite_sheet,
        .cards_sprite_sheet = cards_sprite_sheet,
        .board = &board,
        .player_cards = &player_cards,
        .input = &input,
        .coroutine_runner = &Coroutine.global_runner,
    };

    // const score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    // const hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        if (C.IsKeyPressed(C.KEY_A)) {
            AI.chooseMoves(0, &globals);
        }

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.BLACK);

        for (board.tiles.items) |tile| {
            render(sprite_sheet, tile.pos, tile.sprite);
        }

        const dt = C.GetFrameTime();
        Coroutine.global_runner.update(dt);

        for (board.enemies.items) |e| {
            if (e.health <= 0) continue;

            const pos = board.posFromIndex(e.index) orelse e.position;
            render(sprite_sheet, pos, e.sprite);
        }

        if (board.player) |player| {
            const pos = board.posFromIndex(player.index) orelse player.position;
            render(sprite_sheet, pos, player.sprite);
        }
        for (player_cards.hand.items, 0..) |card, i| {
            render(cards_sprite_sheet, player_cards.getHandPosition(i), card.sprite);
        }

        input.listen(&globals);
    }
}
