const Index = @import("../components/index.zig").Index;

pub const Player = struct {
    index: Index,

    pub fn init(index: Index) Player {
        return .{
            .index = index,
        };
    }
};
