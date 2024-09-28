const std = @import("std");
const C = @import("../c.zig").C;

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;

const Tile = @import("../entities/tile.zig").Tile;
const Enemy = @import("../entities/enemy.zig").Enemy;

pub const Board = struct {
    columns: usize,
    rows: usize,
    tiles: std.ArrayList(Tile),
    enemies: std.ArrayList(*Enemy),

    allocator: std.mem.Allocator,

    pub fn init(
        columns: usize,
        rows: usize,
        pos: Position,
        allocator: std.mem.Allocator,
    ) !Board {
        var tiles = try std.ArrayList(Tile).initCapacity(
            allocator,
            columns * rows,
        );

        for (0..columns) |x| {
            for (0..rows) |y| {
                const tile = Tile.init(.{ .x = x, .y = y }, pos, 1.5);
                tiles.appendAssumeCapacity(tile);
            }
        }

        return .{
            .columns = columns,
            .rows = rows,
            .tiles = tiles,
            .enemies = std.ArrayList(*Enemy).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        self.tiles.deinit();
        self.enemies.deinit();
    }

    pub fn addEnemy(self: *Board, enemy: *Enemy, index: Index) void {
        enemy.index = index;
        self.enemies.append(enemy) catch {};
    }

    fn paintMoves(
        self: *Board,
        enemy: Enemy,
        tint: C.Color,
    ) void {
        var tiles = enemy.movementFunc(self, enemy.index, std.heap.c_allocator);
        defer tiles.deinit();

        for (tiles.items) |*tile| {
            tile.*.sprite.tint = tint;
        }
    }

    pub fn previewMoves(self: *Board, enemy: Enemy) void {
        self.paintMoves(enemy, C.RED);
    }

    pub fn undoPreviewMoves(self: *Board, enemy: Enemy) void {
        self.paintMoves(enemy, C.WHITE);
    }

    pub fn getTile(self: Board, index: Index) ?*Tile {
        if (index.x >= self.columns or index.y >= self.rows) {
            return null;
        }

        return &self.tiles.items[index.x * self.rows + index.y];
    }

    pub fn posFromIndex(self: Board, index: Index) ?Position {
        const tile = self.getTile(index) orelse return null;
        return tile.pos;
    }

    pub fn resetTint(self: *Board) void {
        for (&self.tiles.items) |*tile| {
            tile.*.sprite.tint = C.WHITE;
        }
    }
};
