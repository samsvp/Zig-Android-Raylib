const C = @import("c.zig").C;
const Save = @import("save.zig");
const Movement = @import("movement.zig");

const Board = @import("systems/board.zig").Board;

const Enemy = @import("entities/enemy.zig").Enemy;

const Position = @import("components/position.zig").Position;

const render = @import("systems/render.zig").render;

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

    var score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    var hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        if (C.IsKeyPressed(C.KEY_ENTER) or C.IsMouseButtonPressed(C.MOUSE_BUTTON_LEFT)) {
            score = C.GetRandomValue(1000, 2000);
            hiscore = C.GetRandomValue(2000, 4000);
            _ = Save.SaveStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE), score);
            _ = Save.SaveStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE), hiscore);
        }
        if (C.IsKeyPressed(C.KEY_P)) {
            for (board.enemies.items) |e| {
                board.previewMoves(e.*);
            }
        }
        if (C.IsKeyPressed(C.KEY_U)) {
            for (board.enemies.items) |e| {
                board.undoPreviewMoves(e.*);
            }
        }

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
    }
}
