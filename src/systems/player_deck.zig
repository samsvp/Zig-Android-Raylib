const std = @import("std");

const C = @import("../c.zig").C;
const exit = @import("../utils.zig").exit;
const Movement = @import("../movement.zig");

const Card = @import("../entities/card.zig");
const Sprite = @import("../components/sprite.zig").Sprite;

const random = std.rand.DefaultPrng;

fn readDeck(
    scale: f32,
    deck_path: []const u8,
    allocator: std.mem.Allocator,
) std.ArrayList(Card.Card) {
    var cards = std.ArrayList(Card.Card).initCapacity(
        allocator,
        15,
    ) catch unreachable;

    var file = std.fs.cwd().openFile(deck_path, .{}) catch {
        exit("Error reading deck");
        unreachable;
    };
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var input_stream = buf_reader.reader();

    var buffer: [1024]u8 = undefined;
    while (input_stream.readUntilDelimiterOrEof(&buffer, '\n') catch unreachable) |line| {
        const card_kind = std.meta.stringToEnum(Card.CardKinds, line) orelse {
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
    rand: std.Random.Xoshiro256,

    pub fn init(
        deck_scale: f32,
        card_scale: f32,
        deck_path: []const u8,
        allocator: std.mem.Allocator,
    ) PlayerCards {
        var rand = random.init(@intCast(std.time.timestamp()));
        const cards = readDeck(card_scale, deck_path, allocator);
        rand.random().shuffle(Card.Card, cards.items);

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
            .rand = rand,
        };
    }

    pub fn deinit(self: *PlayerCards) void {
        self.hand.deinit();
        self.deck.deinit();
        self.grave.deinit();
    }

    pub fn draw(self: *PlayerCards, n: usize) void {
        if (self.deck.items.len < n) {
            self.rand.random().shuffle(Card.Card, self.grave.items);
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
};
