pub const C = @import("c.zig").C;

extern fn malloc(size: usize) ?[*]u8;
extern fn realloc(ptr: ?*anyopaque, size: usize) ?[*]u8;
extern fn free(ptr: ?*anyopaque) void;

pub const StorageData = enum {
    POSITION_SCORE,
    POSITION_HISCORE,
};

const STORAGE_DATA_FILE = "storage.data";

pub fn LoadStorageValue(position: c_uint) c_int {
    var value: c_int = 0;
    var dataSize: c_int = 0;
    const fileData = C.LoadFileData(STORAGE_DATA_FILE, &dataSize);

    if (fileData == null) {
        return value;
    }

    if (dataSize < @as(c_int, @intCast(position * 4))) {
        C.TraceLog(
            C.LOG_WARNING,
            "FILEIO: [%s] Failed to find storage position: %i",
            STORAGE_DATA_FILE,
            position,
        );
    } else {
        const dataPtr: [*c]c_int = @ptrCast(@alignCast(fileData));
        value = dataPtr[position];
    }

    C.UnloadFileData(fileData);
    C.TraceLog(
        C.LOG_INFO,
        "FILEIO: [%s] Loaded storage value: %i",
        STORAGE_DATA_FILE,
        value,
    );

    return value;
}

// Save integer value to storage file (to defined position)
// NOTE: Storage positions is directly related to file memory layout (4 bytes each integer)
pub fn SaveStorageValue(position: c_uint, value: c_int) bool {
    var success = false;
    var dataSize: c_int = 0;
    var newDataSize: c_int = 0;
    var fileData = C.LoadFileData(STORAGE_DATA_FILE, &dataSize);
    var newFileData: ?[*c]u8 = null;

    // create fileData
    if (fileData == null) {
        C.TraceLog(
            C.LOG_INFO,
            "FILEIO: [%s] File created successfully",
            STORAGE_DATA_FILE,
        );

        dataSize = @intCast((position + 1) * @sizeOf(c_int));
        fileData = malloc(@intCast(dataSize)).?;
        var dataPtr: [*c]c_int = @ptrCast(@alignCast(fileData));
        dataPtr[position] = value;

        success = C.SaveFileData(STORAGE_DATA_FILE, fileData, dataSize);
        C.UnloadFileData(fileData);

        C.TraceLog(
            C.LOG_INFO,
            "FILEIO: [%s] Saved storage value: %i",
            STORAGE_DATA_FILE,
            value,
        );
        return success;
    }

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
            C.TraceLog(
                C.LOG_WARNING,
                "FILEIO: [%s] Failed to realloc data (%u), position in bytes (%u) bigger than actual file size",
                STORAGE_DATA_FILE,
                dataSize,
                position * @sizeOf(c_int),
            );

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

    success = C.SaveFileData(
        STORAGE_DATA_FILE,
        @ptrCast(newFileData),
        newDataSize,
    );
    free(@ptrCast(newFileData));

    C.TraceLog(
        C.LOG_INFO,
        "FILEIO: [%s] Saved storage value: %i",
        STORAGE_DATA_FILE,
        value,
    );

    return success;
}
