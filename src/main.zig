pub const C = @cImport(@cInclude("raylib.h"));

export fn main() void {
    C.InitWindow(800, 450, "raylib [core] example - basic window");
    defer C.CloseWindow();

    while (!C.WindowShouldClose()) {
        C.BeginDrawing();
        defer C.EndDrawing();

        C.ClearBackground(C.RAYWHITE);
        C.DrawText("Congrats! You created your first window!", 190, 200, 20, C.LIGHTGRAY);
        C.DrawText("Holy shit, it works!", 400, 400, 20, C.LIGHTGRAY);
    }
}
