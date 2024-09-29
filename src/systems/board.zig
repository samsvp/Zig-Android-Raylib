const std = @import("std");
const random = std.rand.DefaultPrng;
const C = @import("../c.zig").C;
const Movement = @import("../movement.zig");

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;

const Enemy = @import("../entities/enemy.zig").Enemy;
const Player = @import("../entities/player.zig").Player;
const Tile = @import("../entities/tile.zig").Tile;

const EnemyKinds = enum {
    TOWER,
    BISHOP,
    KNIGHT,
    QUEEN,
};

pub const TileAttackers = struct {
    arr: std.ArrayList(std.ArrayList(*Enemy)),

    pub fn init(allocator: std.mem.Allocator, size: usize) !TileAttackers {
        var tiles_attackers = try std.ArrayList(
            std.ArrayList(*Enemy),
        ).initCapacity(allocator, size);

        for (0..size) |_| {
            try tiles_attackers.append(
                std.ArrayList(*Enemy).init(allocator),
            );
        }

        return .{ .arr = tiles_attackers };
    }

    pub fn deinit(self: *TileAttackers) void {
        for (self.arr.items) |ta| {
            ta.deinit();
        }
        self.arr.deinit();
    }
};

pub const Board = struct {
    columns: usize,
    rows: usize,
    tiles: std.ArrayList(Tile),
    enemies: std.ArrayList(*Enemy),
    player: Player,
    scale: f32,

    allocator: std.mem.Allocator,

    pub fn init(
        columns: usize,
        rows: usize,
        pos: Position,
        allocator: std.mem.Allocator,
    ) !Board {
        const scale = 1.5;
        var tiles = try std.ArrayList(Tile).initCapacity(
            allocator,
            columns * rows,
        );

        for (0..columns) |x| {
            for (0..rows) |y| {
                const tile = Tile.init(.{ .x = x, .y = y }, pos, scale);
                tiles.appendAssumeCapacity(tile);
            }
        }

        const player_index = .{ .x = columns / 2, .y = rows - 1 };

        return .{
            .columns = columns,
            .rows = rows,
            .tiles = tiles,
            .enemies = std.ArrayList(*Enemy).init(allocator),
            .player = Player.init(5, player_index, scale),
            .scale = scale,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        self.tiles.deinit();
        for (self.enemies.items) |e| {
            std.heap.c_allocator.destroy(e);
        }
        self.enemies.deinit();
    }

    pub fn calculateTilesAttackers(
        self: Board,
        allocator: std.mem.Allocator,
    ) !TileAttackers {
        var tiles_attackers = try TileAttackers.init(
            allocator,
            self.columns * self.rows,
        );

        var s = self;
        for (self.enemies.items) |e| {
            var tiles = e.movementFunc(&s, e.index, std.heap.c_allocator);
            defer tiles.deinit();
            for (tiles.items) |tile| {
                const i = tile.index.x * self.rows + tile.index.y;
                try tiles_attackers.arr.items[i].append(e);
            }
        }

        return tiles_attackers;
    }

    pub fn addEnemy(self: *Board, enemy: *Enemy, index: Index) !void {
        enemy.index = index;
        try self.enemies.append(enemy);
    }

    /// Spawn enemies never spawns a king
    pub fn spawnEnemies(
        self: *Board,
        amount: usize,
        max_queens: usize,
    ) !void {
        var available_indexes = try std.ArrayList(Index).initCapacity(
            std.heap.c_allocator,
            self.columns * self.rows,
        );

        defer available_indexes.deinit();
        for (0..3 * self.rows / 4) |y| {
            for (0..self.columns) |x| {
                available_indexes.appendAssumeCapacity(
                    .{ .x = x, .y = y },
                );
            }
        }

        const seed: u64 = @intCast(std.time.timestamp());
        var rand = random.init(seed);
        var current_queens: i32 = 0;
        for (0..amount) |_| {
            if (available_indexes.items.len == 0) {
                return;
            }

            const max = if (current_queens < max_queens)
                @intFromEnum(EnemyKinds.QUEEN)
            else
                @intFromEnum(EnemyKinds.QUEEN) - 1;

            const chosen_index = rand.random().uintLessThan(
                usize,
                available_indexes.items.len,
            );
            const index = available_indexes.swapRemove(chosen_index);
            const enemy_kind: EnemyKinds = @enumFromInt(
                rand.random().uintAtMost(usize, max),
            );
            const enemy = try std.heap.c_allocator.create(Enemy);
            switch (enemy_kind) {
                EnemyKinds.QUEEN => {
                    enemy.* = Enemy.init(3, .{ .x = 2, .y = 2 }, 1.5, Movement.queen);
                    try self.addEnemy(enemy, index);
                    current_queens += 1;
                },
                EnemyKinds.TOWER => {
                    enemy.* = Enemy.init(3, .{ .x = 2, .y = 1 }, 1.5, Movement.tower);
                    try self.addEnemy(enemy, index);
                },
                EnemyKinds.BISHOP => {
                    enemy.* = Enemy.init(3, .{ .x = 0, .y = 2 }, 1.5, Movement.bishop);
                    try self.addEnemy(enemy, index);
                },
                EnemyKinds.KNIGHT => {
                    enemy.* = Enemy.init(3, .{ .x = 0, .y = 1 }, 1.5, Movement.knight);
                    try self.addEnemy(enemy, index);
                },
            }
        }
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

    pub fn resetPaint(board: *Board) void {
        for (board.tiles.items) |*t| {
            t.*.sprite.tint = C.WHITE;
        }
    }
};
