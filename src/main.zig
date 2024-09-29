const C = @import("c.zig").C;
const Save = @import("save.zig");
const Movement = @import("movement.zig");

const Board = @import("systems/board.zig").Board;
const Input = @import("systems/input.zig").Input;
const render = @import("systems/render.zig").render;

const Enemy = @import("entities/enemy.zig").Enemy;

const Position = @import("components/position.zig").Position;

const std = @import("std");

fn exit(msg: [*c]const u8) void {
    C.TraceLog(
        C.LOG_ERROR,
        msg,
    );

    std.process.exit(1);
}

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
    _ = C.ChangeDirectory("..");
    // end load assets

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

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.BLACK);

        for (board.tiles.items) |tile| {
            render(sprite_sheet, tile.pos, tile.sprite);
        }
        for (board.enemies.items) |e| {
            if (board.posFromIndex(e.index)) |pos| {
                render(sprite_sheet, pos, e.sprite);
            }
        }
        if (board.posFromIndex(board.player.index)) |pos| {
            render(sprite_sheet, pos, board.player.sprite);
        }
    }
}
