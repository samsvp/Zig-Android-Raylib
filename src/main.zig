const std = @import("std");

const C = @import("c.zig").C;
const BS = @import("scenes/battle_scene.zig");

const PlayerCards = @import("systems/player_deck.zig").PlayerCards;
const exit = @import("utils.zig").exit;

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

    var og_player_cards = PlayerCards.init(0, 1.5, "base_deck.txt", std.heap.c_allocator);
    defer og_player_cards.deinit();

    var player_cards = og_player_cards.copy(std.heap.c_allocator);
    defer player_cards.deinit();

    _ = C.ChangeDirectory("..");
    // end load assets
    // const score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    // const hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    var battle_globals = BS.init(
        window_w,
        window_h,
        8,
        6,
        7,
        1,
        std.heap.c_allocator,
        sprite_sheet,
        cards_sprite_sheet,
        &player_cards,
    ) catch unreachable;
    defer BS.deinit(battle_globals);

    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        if (C.IsKeyPressed(C.KEY_R)) {
            BS.deinit(battle_globals);
            player_cards.deinit();
            player_cards = og_player_cards.copy(std.heap.c_allocator);

            battle_globals = BS.init(
                window_w,
                window_h,
                8,
                6,
                7,
                1,
                std.heap.c_allocator,
                sprite_sheet,
                cards_sprite_sheet,
                &player_cards,
            ) catch unreachable;
        }

        const dt = C.GetFrameTime();
        BS.update(battle_globals, dt);
    }
}
