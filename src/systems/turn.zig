const Globals = @import("../scenes/battle_scene.zig").BattleGlobals;

pub const PlayerKind = enum {
    PLAYER,
    COMP,
};

pub const Turn = struct {
    current: i32,
    player_kind: PlayerKind,

    pub fn change(self: *Turn, globals: *Globals) void {
        self.current += 1;
        self.player_kind = switch (self.player_kind) {
            .PLAYER => p_switch: {
                for (globals.player_cards.hand.items) |card| {
                    globals.player_cards.grave.append(card) catch unreachable;
                }
                globals.player_cards.hand.clearRetainingCapacity();
                globals.player_cards.draw(3);
                if (globals.board.player) |*player| {
                    player.*.mana = @min(
                        player.*.mana + 2,
                        player.*.max_mana,
                    );
                }
                break :p_switch PlayerKind.COMP;
            },
            .COMP => PlayerKind.PLAYER,
        };
    }
};
