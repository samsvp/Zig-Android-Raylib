const std = @import("std");
const random = std.rand.DefaultPrng;

const Board = @import("board.zig").Board;
const Character = @import("board.zig").Character;

const Index = @import("../components/index.zig").Index;

fn indexDist(idx1: Index, idx2: Index) usize {
    const dx = if (idx1.x > idx2.x) idx1.x - idx2.x else idx2.x - idx1.x;
    const dy = if (idx1.y > idx2.y) idx1.y - idx2.y else idx2.y - idx1.y;
    return dx + dy;
}

pub const AI = struct {
    pub fn chooseMoves(board: *Board, enemy_i: usize) void {
        if (board.enemies.items.len <= enemy_i) {
            return;
        }

        const enemy = board.enemies.items[enemy_i];
        var tiles = enemy.movementFunc(board, enemy.index, std.heap.c_allocator);
        defer tiles.deinit();

        if (board.player) |player| for (tiles.items) |tile| {
            if (tile.index.equals(player.index)) {
                board.enemyMoveTo(enemy_i, tile.index);
                return;
            }
        };

        const seed: u64 = @intCast(std.time.timestamp());
        var rand = random.init(seed);

        // change of just choosing randomly
        if (rand.random().float(f32) >= 0.5) {
            const max_tries = 32;
            for (0..max_tries) |_| {
                const i = rand.random().uintLessThan(usize, tiles.items.len);
                const tile = tiles.items[i];
                if (indexDist(tile.index, enemy.index) < 3) {
                    continue;
                }

                if (board.isTileEmpty(tile.*)) {
                    board.enemyMoveTo(enemy_i, tiles.items[i].index);
                    return;
                }
            }
        }

        // choose tile that covers the maximum amount of tiles in the board
        var biggest_len: usize = 0;
        var chosen_index = enemy.index;
        var biggest_len_with_player: usize = 0;
        for (tiles.items) |tile| {
            if (!board.isTileEmpty(tile.*)) continue;

            var new_tiles = enemy.movementFunc(board, tile.index, std.heap.c_allocator);
            defer new_tiles.deinit();
            if (board.player) |player| for (new_tiles.items) |new_tile| {
                if (new_tile.index.equals(player.index)) {
                    chosen_index = tile.index;
                    biggest_len_with_player = new_tiles.items.len;
                    continue;
                }
            };

            if (biggest_len_with_player == 0 and new_tiles.items.len > biggest_len) {
                chosen_index = tile.index;
                biggest_len = new_tiles.items.len;
            }
        }
        board.enemyMoveTo(enemy_i, chosen_index);
    }
};
