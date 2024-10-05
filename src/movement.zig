const std = @import("std");
const C = @import("c.zig").C;

const Board = @import("systems/board.zig").Board;
const Index = @import("components/index.zig").Index;
const Tile = @import("entities/tile.zig").Tile;

pub const Kinds = enum {
    tower,
    queen,
    king,
    pawn,
    bishop,
    knight,
};

pub fn getTiles(
    kind: Kinds,
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    const p_tiles = switch (kind) {
        .bishop => bishop(board, index, allocator),
        .king => king(board, index, allocator),
        .knight => knight(board, index, allocator),
        .pawn => pawn(board, index, allocator),
        .queen => queen(board, index, allocator),
        .tower => tower(board, index, allocator),
    };
    return p_tiles;
}

fn moveTowardsDir(
    board: *Board,
    tiles: *std.ArrayList(*Tile),
    index: Index,
    x_dir: i32,
    y_dir: i32,
) void {
    const f_index = index.toVec2();
    for (1..@max(board.rows, board.columns)) |ui| {
        const i: i32 = @intCast(ui);
        const offset = C.Vector2{ .x = @floatFromInt(x_dir * i), .y = @floatFromInt(y_dir * i) };
        const f_tile_index =
            C.Vector2{
            .x = f_index.x + offset.x,
            .y = f_index.y + offset.y,
        };
        if (f_tile_index.x < 0 or f_tile_index.y < 0) {
            break;
        }
        const tile_index = Index.fromVec2(f_tile_index);
        const tile = board.getTile(tile_index) orelse break;
        tiles.append(tile) catch unreachable;
        if (!board.isTileEmpty(tile.*)) {
            break;
        }
    }
}

pub fn king(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        8,
    ) catch unreachable;

    for (0..3) |y| {
        if (index.y == 0 and y == 0) continue;
        for (0..3) |x| {
            if (index.x == 0 and x == 0) continue;

            const tile = board.getTile(.{ .x = index.x + x - 1, .y = index.y + y - 1 }) orelse continue;
            tiles.appendAssumeCapacity(tile);
        }
    }

    return tiles;
}

pub fn pawn(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        1,
    ) catch unreachable;
    if (index.y == 0) return tiles;

    const tile = board.getTile(.{ .x = index.x, .y = index.y - 1 }) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    return tiles;
}

pub fn knight(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        8,
    ) catch unreachable;

    const offsets = [_]Index{
        .{ .x = 2, .y = 1 },
        .{ .x = 1, .y = 2 },
    };
    for (offsets) |offset| {
        if (offset.y <= index.y) {
            if (board.getTile(
                .{ .x = index.x + offset.x, .y = index.y - offset.y },
            )) |tile| {
                tiles.appendAssumeCapacity(tile);
            }
        }
        if (offset.x <= index.x) {
            if (board.getTile(
                .{ .x = index.x - offset.x, .y = index.y + offset.y },
            )) |tile| {
                tiles.appendAssumeCapacity(tile);
            }
        }
        if (offset.x <= index.x and offset.y <= index.y) {
            if (board.getTile(
                .{ .x = index.x - offset.x, .y = index.y - offset.y },
            )) |tile| {
                tiles.appendAssumeCapacity(tile);
            }
        }
        if (board.getTile(
            .{ .x = index.x + offset.x, .y = index.y + offset.y },
        )) |tile| {
            tiles.appendAssumeCapacity(tile);
        }
    }
    return tiles;
}

pub fn bishop(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        board.columns + board.rows,
    ) catch unreachable;

    const tile = board.getTile(index) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    moveTowardsDir(board, &tiles, index, 1, 1);
    moveTowardsDir(board, &tiles, index, 1, -1);
    moveTowardsDir(board, &tiles, index, -1, 1);
    moveTowardsDir(board, &tiles, index, -1, -1);

    return tiles;
}

pub fn tower(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        board.columns + board.rows - 1,
    ) catch unreachable;

    const tile = board.getTile(index) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    moveTowardsDir(board, &tiles, index, 1, 0);
    moveTowardsDir(board, &tiles, index, -1, 0);
    moveTowardsDir(board, &tiles, index, 0, 1);
    moveTowardsDir(board, &tiles, index, 0, -1);
    return tiles;
}

pub fn queen(
    board: *Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Tile) {
    var tiles = std.ArrayList(*Tile).initCapacity(
        allocator,
        board.columns + 3 * (board.rows - 1),
    ) catch unreachable;

    const tile = board.getTile(index) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    moveTowardsDir(board, &tiles, index, 1, 0);
    moveTowardsDir(board, &tiles, index, -1, 0);
    moveTowardsDir(board, &tiles, index, 0, 1);
    moveTowardsDir(board, &tiles, index, 0, -1);
    moveTowardsDir(board, &tiles, index, 1, 1);
    moveTowardsDir(board, &tiles, index, 1, -1);
    moveTowardsDir(board, &tiles, index, -1, 1);
    moveTowardsDir(board, &tiles, index, -1, -1);

    return tiles;
}

test "test" {
    const allocator = std.testing.allocator;

    const columns = 8;
    const rows = 6;
    var board = try Board.init(columns, rows, .{ .x = 0, .y = 0 }, allocator);
    defer board.deinit();

    const pos = Index{ .x = 2, .y = 3 };

    {
        const btiles = bishop(board, pos, allocator);
        const ttiles = tower(board, pos, allocator);
        const qtiles = queen(board, pos, allocator);
        defer {
            btiles.deinit();
            ttiles.deinit();
            qtiles.deinit();
        }
        for (btiles.items) |t| {
            std.debug.print("({}, {}), ", .{ t.index.x, t.index.y });
        }
        std.debug.print("\n", .{});
        std.debug.print("lens: {}, {}, {}\n", .{ btiles.items.len, ttiles.items.len, qtiles.items.len });

        try std.testing.expect(btiles.items.len + ttiles.items.len - 1 == qtiles.items.len);
    }
}
