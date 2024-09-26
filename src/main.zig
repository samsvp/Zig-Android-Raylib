const C = @import("c.zig").C;
const Save = @import("save.zig");

const std = @import("std");

pub export fn main() void {
    C.InitWindow(800, 450, "raylib [core] example - basic window");
    defer C.CloseWindow();

    // load all assets
    // save everything into assets
    _ = C.ChangeDirectory("assets");
    const sprite_sheet = C.LoadTexture("sprites.png");
    defer C.UnloadTexture(sprite_sheet);
    if (sprite_sheet.id <= 0) {
        C.TraceLog(
            C.LOG_ERROR,
            "FILEIO: Could not load spritesheet",
        );

        std.process.exit(1);
    }
    _ = C.ChangeDirectory("..");
    // end load assets

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
        .width = 128.0,
        .height = 128.0,
    };

    var framesCounter: c_int = 0;

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
        } else if (C.IsKeyPressed(C.KEY_SPACE)) {
            // NOTE: If requested position could not be found, value 0 is returned
            score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
            hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));
        }

        framesCounter += 1;

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.RAYWHITE);
        C.DrawText(C.TextFormat("SCORE: %i", score), 280, 130, 40, C.MAROON);
        C.DrawText(C.TextFormat("HI-SCORE: %i", hiscore), 210, 200, 50, C.BLACK);

        C.DrawText(C.TextFormat("frames: %i", framesCounter), 10, 10, 20, C.LIME);

        C.DrawText("Press ENTER to generate and SAVE values", 250, 310, 20, C.LIGHTGRAY);
        C.DrawText("Press SPACE to LOAD values", 252, 350, 20, C.LIGHTGRAY);

        C.DrawTexturePro(
            sprite_sheet,
            frame_rect,
            dest_rect,
            .{ .x = 0.0, .y = 0.0 },
            0.0,
            C.WHITE,
        );
    }
}
