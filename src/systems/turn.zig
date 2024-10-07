pub const PlayerKind = enum {
    PLAYER,
    COMP,
};

pub const Turn = struct {
    current: i32,
    player_kind: PlayerKind,

    pub fn change(self: *Turn) void {
        self.current += 1;
        self.player_kind = switch (self.player_kind) {
            .PLAYER => PlayerKind.COMP,
            .COMP => PlayerKind.PLAYER,
        };
    }
};
