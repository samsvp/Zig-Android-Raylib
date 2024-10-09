const std = @import("std");
const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;
const PlayerCards = @import("player_deck.zig").PlayerCards;
const Board = @import("board.zig").Board;
const TileAttackers = @import("board.zig").TileAttackers;
const Movement = @import("../movement.zig");
const Globals = @import("../globals.zig").Globals;
const exit = @import("../utils.zig").exit;
const Turn = @import("turn.zig");
const R = @import("render.zig");

pub const Input = struct {
    is_move_preview: bool = false,
    lock_: i32 = 0,

    max_lock_time: f32 = 1,
    current_lock_time: f32 = 0,

    fn pointBoxCollision(point: Position, rect: C.Rectangle) bool {
        return rect.x <= point.x and
            rect.x + rect.width >= point.x and
            rect.y <= point.y and
            rect.y + rect.height >= point.y;
    }

    fn checkTACollision(
        board: *Board,
        tiles_attackers: TileAttackers,
        x: usize,
        y: usize,
        mouse_pos: Position,
    ) void {
        const index = Index{ .x = x, .y = y };
        const pos = board.posFromIndex(index) orelse unreachable;
        const i = x * board.rows + y;
        const rect = C.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = 32.0 * board.scale,
            .height = 32.0 * board.scale,
        };
        if (pointBoxCollision(mouse_pos, rect)) {
            const es = tiles_attackers.arr.items[i];
            for (es.items) |e| {
                e.sprite.tint = C.GREEN;
            }
            var tile = board.getTile(index) orelse unreachable;
            tile.sprite.tint = C.ColorTint(tile.sprite.tint, C.BLUE);
        }
    }

    pub fn mouseTileCollision(
        board: *Board,
        mouse_pos: Position,
        tiles_attackers: TileAttackers,
    ) void {
        for (0..board.rows) |y| {
            for (0..board.columns) |x| {
                checkTACollision(board, tiles_attackers, x, y, mouse_pos);
            }
        }
    }

    pub fn addLock(self: *Input) void {
        self.lock_ += 1;
        self.current_lock_time = 0;
    }

    pub fn listen(
        self: *Input,
        dt: f32,
        globals: *Globals,
    ) void {
        if (self.lock_ > 0) {
            self.current_lock_time += dt;
            if (self.current_lock_time > self.max_lock_time) {
                self.lock_ = 0;
                self.current_lock_time = 0;
            }
        }

        var board = globals.board;
        var player_cards = globals.player_cards;

        board.resetPaint();
        for (board.enemies.items) |*e| {
            e.*.sprite.tint = C.WHITE;
        }

        if (globals.turn.player_kind == Turn.PlayerKind.COMP) {
            return;
        }

        if (self.lock_ > 0) {
            return;
        }
        if (self.lock_ < 0) {
            self.lock_ = 0;
        }

        if (C.IsKeyPressed(C.KEY_P)) {
            self.is_move_preview = true;
        }

        if (C.IsKeyPressed(C.KEY_U)) {
            self.is_move_preview = false;
        }

        if (self.is_move_preview) {
            for (board.enemies.items) |e| {
                board.previewMoves(e.*);
            }
        }

        const fw: f32 = @floatFromInt(globals.window_w - R.initial_w);
        const fh: f32 = @floatFromInt(globals.window_h - R.initial_h);
        var mouse_pos = Position{
            .x = @floatFromInt(C.GetMouseX()),
            .y = @floatFromInt(C.GetMouseY()),
        };
        mouse_pos.x -= 0.5 * fw;
        mouse_pos.y -= 0.5 * fh;

        var tiles_attackers = board.calculateTilesAttackers(
            std.heap.c_allocator,
        ) catch unreachable;
        mouseTileCollision(board, mouse_pos, tiles_attackers);
        tiles_attackers.deinit();

        const l_mouse_pressed = C.IsMouseButtonPressed(C.MOUSE_BUTTON_LEFT);
        var i: i32 = @intCast(player_cards.hand.items.len - 1);
        while (i >= 0) : (i -= 1) {
            const u_i: usize = @intCast(i);

            const card = &player_cards.hand.items[u_i];
            const pos = player_cards.getHandPosition(u_i);
            const dest_rect = C.Rectangle{
                .x = pos.x,
                .y = pos.y,
                .width = card.sprite.frame_rect.width * card.sprite.scale,
                .height = card.sprite.frame_rect.height * card.sprite.scale,
            };

            const is_selected = i == player_cards.selected_card;
            const tint = if (is_selected) C.BLUE else C.GREEN;
            card.*.highlighted = player_cards.selected_card < 0 and
                pointBoxCollision(mouse_pos, dest_rect);

            if (l_mouse_pressed and card.highlighted) {
                player_cards.selected_card = @intCast(i);
            }

            if (!card.highlighted and !is_selected) continue;

            const player = &(board.player orelse continue);
            var p_tiles = Movement.getTiles(
                card.card_kind,
                board,
                player.index,
                std.heap.c_allocator,
            );
            defer p_tiles.deinit();

            for (p_tiles.items) |tile| {
                var c = tile.*.sprite.tint;
                tile.*.sprite.tint = C.ColorTint(c, tint);
                if (!is_selected) continue;

                const tile_pos = board.posFromIndex(tile.*.index) orelse unreachable;
                const rect = C.Rectangle{
                    .x = tile_pos.x,
                    .y = tile_pos.y,
                    .width = 32.0 * board.scale,
                    .height = 32.0 * board.scale,
                };

                if (!pointBoxCollision(mouse_pos, rect)) {
                    continue;
                }

                c = tile.*.sprite.tint;
                tile.*.sprite.tint = C.ColorTint(c, C.YELLOW);
                if (!l_mouse_pressed) continue;

                _ = player_cards.play(globals, tile.*);
                if (player_cards.hand.items.len == 0 or player.mana == 0) {
                    std.debug.print("Changing turn to enemy\n", .{});
                    globals.turn.change(globals);
                }
            }
        }

        const r_mouse_pressed = C.IsMouseButtonPressed(C.MOUSE_BUTTON_RIGHT);
        if (r_mouse_pressed) {
            player_cards.selected_card = -1;
        }
    }
};
