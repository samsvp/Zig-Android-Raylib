const std = @import("std");

const C = @import("../c.zig").C;
const exit = @import("../utils.zig").exit;
const Movement = @import("../movement.zig");
const Globals = @import("../globals.zig").Globals;

const Card = @import("../entities/card.zig");
const Tile = @import("../entities/tile.zig").Tile;
const Position = @import("../components/position.zig").Position;
const Sprite = @import("../components/sprite.zig").Sprite;

const Board = @import("board.zig").Board;
const Random = @import("random.zig").Random;

extern fn free(ptr: ?*anyopaque) void;

fn readDeck(
    scale: f32,
    deck_path: [*c]const u8,
    allocator: std.mem.Allocator,
) std.ArrayList(Card.Card) {
    var cards = std.ArrayList(Card.Card).initCapacity(
        allocator,
        15,
    ) catch unreachable;

    const data = C.LoadFileText(deck_path);
    defer free(data);
    const data_slice: [:0]const u8 = std.mem.span(data);

    var it = std.mem.split(u8, data_slice, "\n");
    while (it.next()) |line| {
        if (line.len == 0) continue;

        const card_kind = std.meta.stringToEnum(Movement.Kinds, line) orelse {
            exit("Unknown card");
            unreachable;
        };

        const card = Card.Card.init(scale, card_kind);
        cards.append(card) catch unreachable;
    }
    return cards;
}

pub const PlayerCards = struct {
    sprite: Sprite,
    hand: Card.Hand,
    deck: Card.Deck,
    grave: Card.Graveyard,
    selected_card: i32 = -1,

    pub fn init(
        deck_scale: f32,
        card_scale: f32,
        deck_path: [*c]const u8,
        allocator: std.mem.Allocator,
    ) PlayerCards {
        const cards = readDeck(card_scale, deck_path, allocator);
        Random.shuffle(Card.Card, cards.items);

        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 0,
            .width = 32.0,
            .height = 32.0,
        };

        return .{
            .sprite = .{ .scale = deck_scale, .frame_rect = frame_rect, .tint = C.WHITE },
            .deck = cards,
            .hand = std.ArrayList(Card.Card).initCapacity(allocator, 3) catch unreachable,
            .grave = std.ArrayList(Card.Card).initCapacity(allocator, 15) catch unreachable,
        };
    }

    pub fn deinit(self: *PlayerCards) void {
        self.hand.deinit();
        self.deck.deinit();
        self.grave.deinit();
    }

    pub fn draw(self: *PlayerCards, n: usize) void {
        if (self.deck.items.len < n) {
            Random.shuffle(Card.Card, self.grave.items);
            while (self.grave.items.len > 0) {
                self.deck.append(self.grave.pop()) catch unreachable;
            }
        }

        var draws: usize = 0;
        while (draws < n) {
            self.hand.append(self.deck.pop()) catch unreachable;
            draws += 1;
        }
    }

    pub fn getHandPosition(self: PlayerCards, i: usize) Position {
        const middle: f32 = @floatFromInt(self.hand.items.len / 2);
        const f_i: f32 = @floatFromInt(i);
        const w = self.sprite.frame_rect.width;
        const offset_x = 2.5 * w * (f_i - middle) - w / 2;

        const card = self.hand.items[i];
        var offset_y: f32 = -self.sprite.frame_rect.height;
        offset_y += if (card.highlighted or i == self.selected_card)
            -16.0
        else
            0;

        return .{
            .x = 400.0 + offset_x,
            .y = 400.0 + offset_y,
        };
    }

    pub fn play(self: *PlayerCards, globals: *Globals, tile: Tile) bool {
        var board = globals.board;
        var player = &(board.player orelse return false);
        if (player.mana <= 0 or
            self.selected_card == -1)
        {
            return false;
        }

        std.debug.print("player mana: {}\n", .{player.mana});
        player.mana -= 1;
        const card = self.hand.orderedRemove(@intCast(self.selected_card));
        std.debug.print("new len {}\n", .{self.hand.items.len});
        self.selected_card = -1;
        self.grave.append(card) catch unreachable;

        if (!tile.index.equals(player.index)) {
            board.playerMoveTo(tile.index, globals);
        }

        return true;
    }
};
