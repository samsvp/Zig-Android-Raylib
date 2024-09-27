const std = @import("std");
const Board = @import("board.zig");

/// Returns the possible tiles that can be gone to
/// at the given board and position.
pub const MovementFunc = *const fn (
    Board.Board,
    Board.Position,
    std.mem.Allocator,
) std.ArrayList(*Board.Tile);

pub fn king(
    board: *Board.Board,
    pos: Board.Position,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        8,
    ) catch unreachable;

    for (-1..2) |y| {
        for (-1..2) |x| {
            const tile = board.getTile(.{ .x = pos.x + x, .y = pos.y + y }) orelse continue;
            tiles.appendAssumeCapacity(tile);
        }
    }

    return tiles;
}

pub fn pawn(
    board: Board.Board,
    pos: Board.Position,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        1,
    ) catch unreachable;
    const tile = board.getTile(.{ .x = pos.x, .y = pos.y - 1 }) orelse return tiles;
    tiles.appendAssumeCapacity(tile);
    return tiles;
}

pub fn bishop(
    board: Board.Board,
    pos: Board.Position,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + board.rows,
    ) catch unreachable;

    for (0..board.rows) |row| {
        const dy = if (pos.y > row) pos.y - row else row - pos.y;
        if (dy == 0) {
            if (board.getTile(pos)) |tile| {
                tiles.append(tile) catch unreachable;
            }
            continue;
        }
        if (dy <= pos.x) if (board.getTile(.{ .x = pos.x - dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        };
        if (board.getTile(.{ .x = pos.x + dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
    }
    return tiles;
}

pub fn tower(
    board: Board.Board,
    pos: Board.Position,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + board.rows - 1,
    ) catch unreachable;

    for (0..board.columns) |x| {
        const tile = board.getTile(.{ .x = x, .y = pos.y }) orelse continue;
        tiles.append(tile) catch unreachable;
    }

    for (0..board.rows) |y| {
        if (y == pos.y) {
            continue;
        }

        const tile = board.getTile(.{ .x = pos.x, .y = y }) orelse continue;
        tiles.append(tile) catch unreachable;
    }

    return tiles;
}

pub fn queen(
    board: Board.Board,
    pos: Board.Position,
    allocator: std.mem.Allocator,
) std.ArrayList(*Board.Tile) {
    var tiles = std.ArrayList(*Board.Tile).initCapacity(
        allocator,
        board.columns + 3 * (board.rows - 1),
    ) catch unreachable;

    for (0..board.rows) |row| {
        const dy = if (pos.y > row) pos.y - row else row - pos.y;
        if (dy == 0) {
            for (0..board.columns) |x| {
                const tile = board.getTile(.{ .x = x, .y = pos.y }) orelse continue;
                tiles.append(tile) catch unreachable;
            }
            continue;
        }
        if (dy <= pos.x) if (board.getTile(.{ .x = pos.x - dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        };
        if (board.getTile(.{ .x = pos.x + dy, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
        if (board.getTile(.{ .x = pos.x, .y = row })) |tile| {
            tiles.append(tile) catch unreachable;
        }
    }

    return tiles;
}

test "test" {
    const allocator = std.testing.allocator;

    const columns = 8;
    const rows = 6;
    var board = try Board.Board.init(columns, rows, allocator);
    defer board.deinit();

    const pos = Board.Position{ .x = 2, .y = 3 };

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
            std.debug.print("({}, {}), ", .{ t.pos.x, t.pos.y });
        }
        std.debug.print("\n", .{});
        std.debug.print("lens: {}, {}, {}\n", .{ btiles.items.len, ttiles.items.len, qtiles.items.len });

        try std.testing.expect(btiles.items.len + ttiles.items.len - 1 == qtiles.items.len);
    }
}
