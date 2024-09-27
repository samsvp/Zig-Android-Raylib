const std = @import("std");
const C = @import("c.zig").C;

const Index = @import("components/index.zig").Index;
const Position = @import("components/position.zig").Position;
const Sprite = @import("components/sprite.zig").Sprite;

pub const Tile = struct {
    index: Index,
    pos: Position,
    sprite: Sprite,

    pub fn init(index: Index, offset: Position, scale: f32) Tile {
        const frame_rect = if ((index.x + index.y) % 2 == 0)
            C.Rectangle{
                .x = 64.0,
                .y = 96.0,
                .width = 32.0,
                .height = 32.0,
            }
        else
            C.Rectangle{
                .x = 96.0,
                .y = 96.0,
                .width = 32.0,
                .height = 32.0,
            };

        const p = Position{
            .x = @floatFromInt(index.x),
            .y = @floatFromInt(index.y),
        };

        return .{
            .index = index,
            .pos = .{
                .x = p.x * 32.0 * scale + offset.x,
                .y = p.y * 32.0 * scale + offset.y,
            },
            .sprite = .{
                .scale = scale,
                .frame_rect = frame_rect,
                .tint = C.WHITE,
            },
        };
    }
};

pub const Board = struct {
    columns: usize,
    rows: usize,
    tiles: std.ArrayList(Tile),

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
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        self.tiles.deinit();
    }

    pub fn getTile(self: Board, pos: Index) ?*Tile {
        if (pos.x >= self.columns or pos.y >= self.rows) {
            return null;
        }

        return &self.tiles.items[pos.x * self.rows + pos.y];
    }
};
