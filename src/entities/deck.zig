const std = @import("std");

const C = @import("../c.zig").C;
const exit = @import("../utils.zig").exit;
const Movement = @import("../movement.zig");

const Card = @import("card.zig").Card;
const Sprite = @import("../components/sprite.zig").Sprite;

const MovementKinds = enum {
    tower,
    queen,
    king,
    pawn,
    bishop,
    knight,
};

fn readDeck(
    scale: f32,
    deck_path: []const u8,
    allocator: std.mem.Allocator,
) std.ArrayList(Card) {
    var cards = std.ArrayList(Card).initCapacity(
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
        const card_kind = std.meta.stringToEnum(MovementKinds, line) orelse {
            exit("Unknown card");
            unreachable;
        };

        const card = switch (card_kind) {
            .pawn => Card.init(scale, Movement.pawn),
            .tower => Card.init(scale, Movement.tower),
            .queen => Card.init(scale, Movement.queen),
            .bishop => Card.init(scale, Movement.bishop),
            .king => Card.init(scale, Movement.king),
            .knight => Card.init(scale, Movement.knight),
        };
        cards.append(card) catch unreachable;
    }
    return cards;
}

pub const Deck = struct {
    sprite: Sprite,
    cards: std.ArrayList(Card),

    pub fn init(
        deck_scale: f32,
        card_scale: f32,
        deck_path: []const u8,
        allocator: std.mem.Allocator,
    ) Deck {
        const cards = readDeck(card_scale, deck_path, allocator);

        const frame_rect = C.Rectangle{
            .x = 0,
            .y = 0,
            .width = 32.0,
            .height = 32.0,
        };

        return .{
            .sprite = .{ .scale = deck_scale, .frame_rect = frame_rect, .tint = C.WHITE },
            .cards = cards,
        };
    }

    pub fn deinit(self: *Deck) void {
        self.cards.deinit();
    }
};
