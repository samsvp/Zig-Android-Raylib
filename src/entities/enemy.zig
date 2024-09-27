const std = @import("std");

const C = @import("../c.zig").C;

const Board = @import("board.zig");

// components
const Index = @import("../components/index.zig").Index;
const Health = @import("../components/health.zig").Health;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

const MovementFunc = @import("../movement.zig").MovementFunc;

pub const Enemy = struct {
    health: Health,
    position: Position,
    index: Index,
    movementFunc: MovementFunc,
    sprite: Sprite,

    pub fn init(
        health: Health,
        board: Board.Board,
        index: Index,
        spriteIndex: Index,
        scale: f32,
        movementFunc: MovementFunc,
    ) Enemy {
        const p = Position{
            .x = @floatFromInt(spriteIndex.x),
            .y = @floatFromInt(spriteIndex.y),
        };
        const frame_rect = C.Rectangle{
            .x = p.x * 32.0,
            .y = p.y * 32.0,
            .width = 32.0,
            .height = 32.0,
        };

        return .{
            .health = health,
            .index = index,
            .position = board.posFromIndex(index) orelse .{ .x = 0, .y = 0 },
            .movementFunc = movementFunc,
            .sprite = .{ .scale = scale, .frame_rect = frame_rect, .tint = C.WHITE },
        };
    }

    pub fn possibleMoves(
        self: Enemy,
        board: Board.Board,
        allocator: std.mem.Allocator,
    ) std.ArrayList(*Board.Tile) {
        return self.movementFunc(board, self.index, allocator);
    }

    fn paintMoves(
        self: Enemy,
        board: *Board.Board,
        tint: C.Color,
    ) void {
        var tiles = self.possibleMoves(board.*, std.heap.c_allocator);
        defer tiles.deinit();

        for (tiles.items) |*tile| {
            tile.*.sprite.tint = tint;
        }
    }

    pub fn previewMoves(
        self: Enemy,
        board: *Board.Board,
    ) void {
        self.paintMoves(board, C.RED);
    }

    pub fn undoPreviewMoves(
        self: Enemy,
        board: *Board.Board,
    ) void {
        self.paintMoves(board, C.WHITE);
    }
};
