const std = @import("std");
const Board = @import("entities/board.zig");
const Index = @import("components/index.zig").Index;

/// Returns the possible tiles that can be gone to
/// at the given board and position.
pub const MovementFunc = *const fn (
    Board.Board,
    Index,
    std.mem.Allocator,
) std.ArrayList(*Board.Tile);

pub fn king(
    board: *Board.Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        8,
    ) catch unreachable;

    for (-1..2) |y| {
        for (-1..2) |x| {
            const tile = board.getTile(.{ .x = index.x + x, .y = index.y + y }) orelse continue;
            tiles.appendAssumeCapacity(tile);
        }
    }

    return tiles;
}

pub fn pawn(
    board: Board.Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        1,
    ) catch unreachable;
    const tile = board.getTile(.{ .x = index.x, .y = index.y - 1 }) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    return tiles;
}

pub fn bishop(
    board: Board.Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + board.rows,
    ) catch unreachable;

    for (0..board.rows) |row| {
        const dy = if (index.y > row) index.y - row else row - index.y;
        if (dy == 0) {
            if (board.getTile(index)) |tile| {
                tiles.append(tile) catch unreachable;
            }
            continue;
        }
        if (dy <= index.x) if (board.getTile(.{ .x = index.x - dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        };
        if (board.getTile(.{ .x = index.x + dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
    }
    return tiles;
}

pub fn tower(
    board: Board.Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + board.rows - 1,
    ) catch unreachable;

    for (0..board.columns) |x| {
        const tile = board.getTile(.{ .x = x, .y = index.y }) orelse continue;
        tiles.append(tile) catch unreachable;
    }

    for (0..board.rows) |y| {
        if (y == index.y) {
            continue;
        }

        const tile = board.getTile(.{ .x = index.x, .y = y }) orelse continue;
        tiles.append(tile) catch unreachable;
    }

    return tiles;
}

pub fn queen(
    board: Board.Board,
    index: Index,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + 3 * (board.rows - 1),
    ) catch unreachable;

    for (0..board.rows) |row| {
        const dy = if (index.y > row) index.y - row else row - index.y;
        if (dy == 0) {
            for (0..board.columns) |x| {
                const tile = board.getTile(.{ .x = x, .y = index.y }) orelse continue;
                tiles.append(tile) catch unreachable;
            }
            continue;
        }
        if (dy <= index.x) if (board.getTile(.{ .x = index.x - dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        };
        if (board.getTile(.{ .x = index.x + dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
        if (board.getTile(.{ .x = index.x, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
    }

    return tiles;
}

test "test" {
    const allocator = std.testing.allocator;

    const columns = 8;
    const rows = 6;
    var board = try Board.Board.init(columns, rows, .{ .x = 0, .y = 0 }, allocator);
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
