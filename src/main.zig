const std = @import("std");

const C = @import("c.zig").C;
const BS = @import("scenes/battle_scene.zig");
const Sprite = @import("components/sprite.zig").Sprite;

const PlayerCards = @import("systems/player_deck.zig").PlayerCards;
const exit = @import("utils.zig").exit;

fn loadSheet(name: [*c]const u8) C.Texture {
    const sprite_sheet = C.LoadTexture(name);
    if (sprite_sheet.id <= 0) {
        exit("FILEIO: Could not load spritesheet");
    }
    return sprite_sheet;
}

pub export fn main() void {
    const window_w = 800;
    const window_h = 450;
    C.InitWindow(window_w, window_h, "raylib [core] example - basic window");
    defer C.CloseWindow();

    // load all assets
    // save everything into assets
    _ = C.ChangeDirectory("assets");

    const sprite_sheet = loadSheet("sprites.png");
    defer C.UnloadTexture(sprite_sheet);

    const pieces_sheet = loadSheet("pieces.png");
    defer C.UnloadTexture(pieces_sheet);

    const cloud_texture = loadSheet("cloud.png");
    defer C.UnloadTexture(pieces_sheet);

    const cards_sprite_sheet = loadSheet("card-sprites.png");
    defer C.UnloadTexture(cards_sprite_sheet);

    var og_player_cards = PlayerCards.init(0, 1.5, "base_deck.txt", std.heap.c_allocator);
    defer og_player_cards.deinit();

    var player_cards = og_player_cards.copy(std.heap.c_allocator);
    defer player_cards.deinit();

    _ = C.ChangeDirectory("..");

    const cloud_sprite = Sprite{
        .frame_rect = .{ .x = 0, .y = 0, .width = 64, .height = 48 },
        .scale = 3.0,
        .tint = C.WHITE,
    };
    // end load assets
    // const score = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_SCORE));
    // const hiscore = Save.LoadStorageValue(@intFromEnum(Save.StorageData.POSITION_HISCORE));

    var battle_globals = BS.init(
        window_w,
        window_h,
        8,
        6,
        8,
        2,
        std.heap.c_allocator,
        sprite_sheet,
        pieces_sheet,
        cards_sprite_sheet,
        cloud_sprite,
        cloud_texture,
        &player_cards,
    ) catch unreachable;
    defer BS.deinit(battle_globals);

    C.SetTargetFPS(60);
    while (!C.WindowShouldClose()) {
        if (C.IsKeyPressed(C.KEY_R)) {
            BS.deinit(battle_globals);
            player_cards.deinit();
            player_cards = og_player_cards.copy(std.heap.c_allocator);

            const new_battle_globals = BS.init(
                window_w,
                window_h,
                8,
                6,
                8,
                2,
                std.heap.c_allocator,
                sprite_sheet,
                pieces_sheet,
                cards_sprite_sheet,
                cloud_sprite,
                cloud_texture,
                &player_cards,
            ) catch unreachable;
            new_battle_globals.window_h = battle_globals.window_h;
            new_battle_globals.window_w = battle_globals.window_w;
            battle_globals = new_battle_globals;
        }

        const dt = C.GetFrameTime();
        BS.update(battle_globals, dt);
    }
}
