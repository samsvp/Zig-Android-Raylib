pub const C = @cImport(@cInclude("raylib.h"));

extern fn malloc(size: usize) ?[*]u8;
extern fn realloc(ptr: ?*anyopaque, size: usize) ?[*]u8;
extern fn free(ptr: ?*anyopaque) void;

const StorageData = enum {
    POSITION_SCORE,
    POSITION_HISCORE,
};

const STORAGE_DATA_FILE = "storage.data";

fn LoadStorageValue(position: c_uint) c_int {
    var value: c_int = 0;
    var dataSize: c_int = 0;
    const fileData = C.LoadFileData(STORAGE_DATA_FILE, &dataSize);

    if (fileData != null) {
        if (dataSize < @as(c_int, @intCast(position * 4))) {
            C.TraceLog(C.LOG_WARNING, "FILEIO: [%s] Failed to find storage position: %i", STORAGE_DATA_FILE, position);
        } else {
            const dataPtr: [*c]c_int = @ptrCast(@alignCast(fileData));
            value = dataPtr[position];
        }

        C.UnloadFileData(fileData);

        C.TraceLog(C.LOG_INFO, "FILEIO: [%s] Loaded storage value: %i", STORAGE_DATA_FILE, value);
    }

    return value;
}

// Save integer value to storage file (to defined position)
// NOTE: Storage positions is directly related to file memory layout (4 bytes each integer)
fn SaveStorageValue(position: c_uint, value: c_int) bool {
    var success = false;
    var dataSize: c_int = 0;
    var newDataSize: c_int = 0;
    var fileData = C.LoadFileData(STORAGE_DATA_FILE, &dataSize);
    var newFileData: ?[*c]u8 = null;

    if (fileData != null) {
        if (dataSize <= (position * @sizeOf(c_int))) {
            // Increase data size up to position and store value
            newDataSize = @intCast((position + 1) * @sizeOf(c_int));
            newFileData = realloc(fileData, @intCast(newDataSize));

            if (newFileData != null) {
                // RL_REALLOC succeded
                var dataPtr: [*c]c_int = @ptrCast(@alignCast(newFileData));
                dataPtr[position] = value;
            } else {
                // RL_REALLOC failed
                C.TraceLog(C.LOG_WARNING, "FILEIO: [%s] Failed to realloc data (%u), position in bytes (%u) bigger than actual file size", STORAGE_DATA_FILE, dataSize, position * @sizeOf(c_int));

                // We store the old size of the file
                newFileData = fileData;
                newDataSize = @intCast(dataSize);
            }
        } else {
            // Store the old size of the file
            newFileData = fileData;
            newDataSize = dataSize;

            // Replace value on selected position
            var dataPtr: [*c]c_int = @ptrCast(@alignCast(newFileData));
            dataPtr[position] = value;
        }

        success = C.SaveFileData(STORAGE_DATA_FILE, @ptrCast(newFileData), newDataSize);
        free(@ptrCast(newFileData));

        C.TraceLog(C.LOG_INFO, "FILEIO: [%s] Saved storage value: %i", STORAGE_DATA_FILE, value);
    } else {
        C.TraceLog(C.LOG_INFO, "FILEIO: [%s] File created successfully", STORAGE_DATA_FILE);

        dataSize = @intCast((position + 1) * @sizeOf(c_int));
        fileData = malloc(@intCast(dataSize)).?;
        var dataPtr: [*c]c_int = @ptrCast(@alignCast(fileData));
        dataPtr[position] = value;

        success = C.SaveFileData(STORAGE_DATA_FILE, fileData, dataSize);
        C.UnloadFileData(fileData);

        C.TraceLog(C.LOG_INFO, "FILEIO: [%s] Saved storage value: %i", STORAGE_DATA_FILE, value);
    }

    return success;
}

export fn main() void {
    C.InitWindow(800, 450, "raylib [core] example - basic window");
    defer C.CloseWindow();

    var score: c_int = 0;
    var hiscore: c_int = 0;
    var framesCounter: c_int = 0;

    score = LoadStorageValue(@intFromEnum(StorageData.POSITION_SCORE));
    hiscore = LoadStorageValue(@intFromEnum(StorageData.POSITION_HISCORE));

    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        C.BeginDrawing();
        defer C.EndDrawing();

        // Update
        //----------------------------------------------------------------------------------
        if (C.IsKeyPressed(C.KEY_ENTER) or C.IsMouseButtonPressed(C.MOUSE_BUTTON_LEFT)) {
            score = C.GetRandomValue(1000, 2000);
            hiscore = C.GetRandomValue(2000, 4000);
            _ = SaveStorageValue(@intFromEnum(StorageData.POSITION_SCORE), score);
            _ = SaveStorageValue(@intFromEnum(StorageData.POSITION_HISCORE), hiscore);
        } else if (C.IsKeyPressed(C.KEY_SPACE)) {
            // NOTE: If requested position could not be found, value 0 is returned
            score = LoadStorageValue(@intFromEnum(StorageData.POSITION_SCORE));
            hiscore = LoadStorageValue(@intFromEnum(StorageData.POSITION_HISCORE));
        }

        framesCounter += 1;

        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.RAYWHITE);
        C.DrawText(C.TextFormat("SCORE: %i", score), 280, 130, 40, C.MAROON);
        C.DrawText(C.TextFormat("HI-SCORE: %i", hiscore), 210, 200, 50, C.BLACK);

        C.DrawText(C.TextFormat("frames: %i", framesCounter), 10, 10, 20, C.LIME);

        C.DrawText("Press R to generate random numbers", 220, 40, 20, C.LIGHTGRAY);
        C.DrawText("Press ENTER to SAVE values", 250, 310, 20, C.LIGHTGRAY);
        C.DrawText("Press SPACE to LOAD values", 252, 350, 20, C.LIGHTGRAY);
    }
}
