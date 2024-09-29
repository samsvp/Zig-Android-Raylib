const std = @import("std");
const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;

const Board = @import("board.zig").Board;
const TileAttackers = @import("board.zig").TileAttackers;

pub const Input = struct {
    is_move_preview: bool = false,

    fn pointBoxCollision(point: Position, rect: C.Rectangle) bool {
        return rect.x <= point.x and
            rect.x + rect.width >= point.x and
            rect.y <= point.y and
            rect.y + rect.height >= point.y;
    }

    fn checkCollision(
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
                e.sprite.tint = C.RED;
            }
            var tile = board.getTile(index) orelse unreachable;
            tile.sprite.tint = C.BLUE;
        }
    }

    pub fn mouseTileCollision(
        board: *Board,
        tiles_attackers: TileAttackers,
    ) void {
        const mouse_pos = Position{
            .x = @floatFromInt(C.GetMouseX()),
            .y = @floatFromInt(C.GetMouseY()),
        };
        for (0..board.rows) |y| {
            for (0..board.columns) |x| {
                checkCollision(board, tiles_attackers, x, y, mouse_pos);
            }
        }
    }

    pub fn listen(
        self: *Input,
        board: *Board,
        tiles_attackers: TileAttackers,
    ) void {
        board.resetPaint();
        for (board.enemies.items) |*e| {
            e.*.sprite.tint = C.WHITE;
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

        mouseTileCollision(board, tiles_attackers);
    }
};
