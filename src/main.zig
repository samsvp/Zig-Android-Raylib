const std = @import("std");

const C = @import("c.zig").C;
const exit = @import("utils.zig").exit;
const Save = @import("save.zig");
const Movement = @import("movement.zig");

const AI = @import("systems/AI.zig").AI;
const Board = @import("systems/board.zig").Board;
const Input = @import("systems/input.zig").Input;
const render = @import("systems/render.zig").render;

const Enemy = @import("entities/enemy.zig").Enemy;
const PlayerCards = @import("systems/player_deck.zig").PlayerCards;

const Position = @import("components/position.zig").Position;

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
    var player_cards = PlayerCards.init(0, 0, "base_deck.txt", std.heap.c_allocator);
    defer player_cards.deinit();

    _ = C.ChangeDirectory("..");
    // end load assets

    player_cards.draw(3);
    std.debug.print("hand len: {}\n", .{player_cards.hand.items.len});

    const board_pos = Position{ .x = 800.0 / 4.0, .y = 450.0 / 16.0 };
    var board = Board.init(8, 6, board_pos, std.heap.c_allocator) catch {
        exit("BOARD: could not create board, OOM");
        unreachable;
    };
    defer board.deinit();
    board.spawnEnemies(7, 1) catch exit("BOARD: could not spawn enemies, OOM");

    var tiles_attackers = board.calculateTilesAttackers(
        std.heap.c_allocator,
    ) catch {
        exit("OOM");
        unreachable;
    };
    defer tiles_attackers.deinit();

    // const score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    // const hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    var input = Input{};
    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        input.listen(&board, tiles_attackers);

        if (C.IsKeyPressed(C.KEY_A)) {
            AI.chooseMoves(&board, 0);
            tiles_attackers.deinit();
            tiles_attackers = board.calculateTilesAttackers(
                std.heap.c_allocator,
            ) catch {
                exit("OOM");
                unreachable;
            };
        }
        if (C.IsKeyPressed(C.KEY_S)) {
            AI.chooseMoves(&board, 1);
            tiles_attackers.deinit();
            tiles_attackers = board.calculateTilesAttackers(
                std.heap.c_allocator,
            ) catch {
                exit("OOM");
                unreachable;
            };
        }
        if (C.IsKeyPressed(C.KEY_D)) {
            AI.chooseMoves(&board, 2);
            tiles_attackers.deinit();
            tiles_attackers = board.calculateTilesAttackers(
                std.heap.c_allocator,
            ) catch {
                exit("OOM");
                unreachable;
            };
        }
        if (C.IsKeyPressed(C.KEY_F)) {
            AI.chooseMoves(&board, 3);
            tiles_attackers.deinit();
            tiles_attackers = board.calculateTilesAttackers(
                std.heap.c_allocator,
            ) catch {
                exit("OOM");
                unreachable;
            };
        }

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.BLACK);

        for (board.tiles.items) |tile| {
            render(sprite_sheet, tile.pos, tile.sprite);
        }
        for (board.enemies.items) |e| {
            if (e.health <= 0) continue;

            if (board.posFromIndex(e.index)) |pos| {
                render(sprite_sheet, pos, e.sprite);
            }
        }

        if (board.player) |player| {
            if (board.posFromIndex(player.index)) |pos| {
                render(sprite_sheet, pos, player.sprite);
            }
        }
    }
}
