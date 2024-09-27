const Board = @import("board.zig");
const C = @import("c.zig").C;
const Save = @import("save.zig");

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

    var board = Board.Board.init(8, 6, std.heap.c_allocator) catch {
        exit("BOARD: could not create board, OOM");
        unreachable;
    };
    defer board.deinit();

    const pos = C.Vector2{ .x = 400, .y = 225 };
    const frame_rect = C.Rectangle{
        .x = 0.0,
        .y = 0.0,
        .width = 32.0,
        .height = 32.0,
    };
    const dest_rect = C.Rectangle{
        .x = pos.x,
        .y = pos.y,
        .width = 64.0,
        .height = 64.0,
    };

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

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.BLACK);

        board.render(
            sprite_sheet,
            .{ .x = 800.0 / 4.0, .y = 450.0 / 4.0 },
            1.5,
        );

        C.DrawTexturePro(
            sprite_sheet,
            frame_rect,
            dest_rect,
            .{ .x = 0.0, .y = 0.0 },
            0.0,
            C.WHITE,
        );

        C.DrawText(C.TextFormat("SCORE: %i", score), 280, 130, 40, C.MAROON);
        C.DrawText(C.TextFormat("HI-SCORE: %i", hiscore), 210, 200, 50, C.BLACK);

        C.DrawText("Press ENTER to generate and SAVE values", 250, 310, 20, C.LIGHTGRAY);
        C.DrawText("Press SPACE to LOAD values", 252, 350, 20, C.LIGHTGRAY);
    }
}
