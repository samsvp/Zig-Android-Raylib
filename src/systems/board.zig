const std = @import("std");
const C = @import("../c.zig").C;
const Movement = @import("../movement.zig");

const Index = @import("../components/index.zig").Index;
const Position = @import("../components/position.zig").Position;

const Enemy = @import("../entities/enemy.zig").Enemy;
const Player = @import("../entities/player.zig").Player;
const Tile = @import("../entities/tile.zig").Tile;
const Coroutine = @import("coroutine.zig");
const Input = @import("input.zig").Input;

const MovementFunc = *const fn (
    *Board,
    Index,
    std.mem.Allocator,
) std.ArrayList(*Tile);

const EnemyKinds = enum {
    TOWER,
    BISHOP,
    KNIGHT,
    QUEEN,
};

pub const Character = union(enum) {
    player: *Player,
    enemy: *Enemy,
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

const MoveCoroutine = struct {
    target_index: Index,
    target_position: Position,
    char: Character,
    cb_routine: ?Coroutine.Coroutine,
    input: *Input,

    pub fn init(
        board: *Board,
        target_index: Index,
        char: Character,
        cb_routine: ?Coroutine.Coroutine,
        input: *Input,
    ) MoveCoroutine {
        switch (char) {
            inline else => |c| {
                c.*.position = board.posFromIndex(c.*.index).?;
                c.*.index = .{ .x = board.columns, .y = board.rows };
            },
        }

        const target_position = board.posFromIndex(target_index).?;
        input.lock += 1;
        return .{
            .target_index = target_index,
            .target_position = target_position,
            .char = char,
            .cb_routine = cb_routine,
            .input = input,
        };
    }

    pub fn move(self: *MoveCoroutine, dt: f32) bool {
        switch (self.char) {
            inline else => |c| {
                const dx = self.target_position.x - c.*.position.x;
                const dy = self.target_position.y - c.*.position.y;
                const move_direction = .{
                    .x = dx * dx / (dx * dx + dy * dy),
                    .y = dy * dy / (dx * dx + dy * dy),
                };
                const speed = 1000.0;
                c.*.position.x += std.math.sign(dx) * move_direction.x * dt * speed;
                c.*.position.y += std.math.sign(dy) * move_direction.y * dt * speed;

                const delta = @abs(dx) + @abs(dy);
                if (delta < 10.0) {
                    c.*.index = self.target_index;
                    c.*.position = self.target_position;
                    self.input.lock -= 1;
                    if (self.cb_routine) |routine| {
                        Coroutine.global_runner.add(routine);
                    }
                    std.heap.c_allocator.destroy(self);
                    return true;
                }
                return false;
            },
        }
    }
};

pub const Board = struct {
    columns: usize,
    rows: usize,
    tiles: std.ArrayList(Tile),
    enemies: std.ArrayList(*Enemy),
    player: ?Player,
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

    pub fn damageChar(character: Character) void {
        switch (character) {
            inline else => |char| {
                char.*.health -= 1;
                if (char.health < 0) {
                    char.*.health = 0;
                }
            },
        }
    }

    fn moveTo(
        self: *Board,
        char: Character,
        target_index: Index,
        input: *Input,
    ) void {
        const current_index = switch (char) {
            inline else => |*c| &c.*.index,
        };
        var target_new_index = Index{ .x = 0, .y = 0 };
        var target_char: ?Character = null;
        var cb_routine: ?Coroutine.Coroutine = null;
        defer {
            const move_cr = std.heap.c_allocator.create(MoveCoroutine) catch unreachable;
            move_cr.* = MoveCoroutine.init(
                self,
                target_index,
                char,
                cb_routine,
                input,
            );
            const c = Coroutine.Coroutine.init(move_cr, MoveCoroutine.move);
            Coroutine.global_runner.add(c);
        }

        const targeted_char = self.getCharacterAtIndex(target_index) orelse {
            // tile is empty, just move
            return;
        };

        // tile is not empty
        const current_f_index = current_index.toVec2();

        const target_findex = target_index.toVec2();
        const x_dir = std.math.sign(target_findex.x - current_f_index.x);
        const y_dir = std.math.sign(target_findex.y - current_f_index.y);
        const target_new_findex = C.Vector2{
            .x = target_findex.x + x_dir,
            .y = target_findex.y + y_dir,
        };

        target_char = self.getCharacterAtIndex(target_index).?;
        if (target_new_findex.x < 0 or target_new_findex.y < 0 or
            target_new_findex.x >= @as(f32, @floatFromInt(self.columns)) or
            target_new_findex.y >= @as(f32, @floatFromInt(self.rows)))
        { // sent target out of bounds, kill
            switch (target_char.?) {
                .player => self.player = null,
                .enemy => |*enemy| enemy.*.health = 0,
            }
            return;
        }

        target_new_index = Index.fromVec2(target_new_findex);
        const char_behind_target = self.getCharacterAtIndex(target_new_index) orelse {
            damageChar(targeted_char);
            const move_routine = std.heap.c_allocator.create(
                MoveCoroutine,
            ) catch unreachable;
            move_routine.* = MoveCoroutine.init(
                self,
                target_new_index,
                targeted_char,
                null,
                input,
            );
            cb_routine = Coroutine.Coroutine.init(move_routine, MoveCoroutine.move);
            return;
        };
        switch (targeted_char) {
            inline else => |*c| c.*.health = 0,
        }
        damageChar(char_behind_target);
    }

    pub fn playerMoveTo(
        self: *Board,
        target_index: Index,
        input: *Input,
    ) void {
        if (self.player) |*player| {
            self.moveTo(.{ .player = player }, target_index, input);
        }
    }

    pub fn enemyMoveTo(
        self: *Board,
        enemy_i: usize,
        target_index: Index,
        input: *Input,
    ) void {
        const enemy = self.enemies.items[enemy_i];
        self.moveTo(.{ .enemy = enemy }, target_index, input);
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

        const seed: c_uint = @intFromFloat(C.GetTime());
        C.SetRandomSeed(seed);
        var current_queens: i32 = 0;
        for (0..amount) |_| {
            if (available_indexes.items.len == 0) {
                return;
            }

            const max = if (current_queens < max_queens)
                @intFromEnum(EnemyKinds.QUEEN)
            else
                @intFromEnum(EnemyKinds.QUEEN) - 1;

            const chosen_index = C.GetRandomValue(
                0,
                @intCast(available_indexes.items.len - 1),
            );
            const index = available_indexes.swapRemove(@intCast(chosen_index));
            const enemy_kind: EnemyKinds = @enumFromInt(
                C.GetRandomValue(0, max),
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

    pub fn isTileAtIndexEmpty(self: Board, index: Index) bool {
        for (self.enemies.items) |e| {
            if (e.health <= 0) continue;

            if (e.index.equals(index)) {
                return false;
            }
        }

        if (self.player) |player| {
            return !player.index.equals(index);
        }
        return true;
    }

    pub fn isTileEmpty(self: Board, tile: Tile) bool {
        const index = tile.index;
        return self.isTileAtIndexEmpty(index);
    }

    pub fn getCharacterAtIndex(self: *Board, index: Index) ?Character {
        for (self.enemies.items) |e| {
            if (e.health <= 0) continue;

            if (e.index.equals(index)) {
                return Character{ .enemy = e };
            }
        }

        if (self.player) |*player| if (player.*.index.equals(index)) {
            return Character{ .player = player };
        };
        return null;
    }

    pub fn getCharacterInTile(self: Board, tile: Tile) ?Character {
        const index = tile.index;
        return self.getCharacterAtIndex(index);
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
        if (enemy.health <= 0) return;

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
