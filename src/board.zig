const std = @import("std");
const C = @import("c.zig").C;

pub const Position = struct {
    x: usize,
    y: usize,
};

pub const Tile = struct {
    pos: Position,
};

pub const Board = struct {
    columns: usize,
    rows: usize,
    tiles: std.ArrayList(Tile),

    allocator: std.mem.Allocator,

    pub fn init(
        columns: usize,
        rows: usize,
        allocator: std.mem.Allocator,
    ) !Board {
        var tiles = try std.ArrayList(Tile).initCapacity(
            allocator,
            columns * rows,
        );
        for (0..columns) |x| {
            for (0..rows) |y| {
                tiles.appendAssumeCapacity(.{
                    .pos = .{
                        .x = x,
                        .y = y,
                    },
                });
            }
        }

        return .{
            .columns = columns,
            .rows = rows,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        self.tiles.deinit();
    }

    pub fn getTile(self: Board, pos: Position) ?*Tile {
        if (pos.x >= self.columns or pos.y >= self.rows) {
            return null;
        }

        return &self.tiles.items[pos.x * self.rows + pos.y];
    }

    pub fn render(
        self: Board,
        texture: C.Texture,
        pos: C.Vector2,
        scale: f32,
    ) void {
        const frame_rect1 = C.Rectangle{
            .x = 64.0,
            .y = 96.0,
            .width = 32.0,
            .height = 32.0,
        };
        const frame_rect2 = C.Rectangle{
            .x = 96.0,
            .y = 96.0,
            .width = 32.0,
            .height = 32.0,
        };

        for (self.tiles.items) |tile| {
            const p = C.Vector2{
                .x = @floatFromInt(tile.pos.x),
                .y = @floatFromInt(tile.pos.y),
            };

            const dest_rect = C.Rectangle{
                .x = p.x * 32.0 * scale + pos.x,
                .y = p.y * 32.0 * scale + pos.y,
                .width = 32.0 * scale,
                .height = 32.0 * scale,
            };

            const frame_rect = if ((tile.pos.x + tile.pos.y) % 2 == 0)
                frame_rect1
            else
                frame_rect2;

            C.DrawTexturePro(
                texture,
                frame_rect,
                dest_rect,
                .{ .x = 0.0, .y = 0.0 },
                0.0,
                C.WHITE,
            );
        }
    }
};
