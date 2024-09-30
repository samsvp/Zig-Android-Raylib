const C = @import("../c.zig").C;

pub const Index = struct {
    x: usize,
    y: usize,

    pub fn equals(self: Index, other: Index) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn toVec2(self: Index) C.Vector2 {
        return .{ .x = @floatFromInt(self.x), .y = @floatFromInt(self.y) };
    }

    pub fn fromVec2(v: C.Vector2) Index {
        return .{ .x = @intFromFloat(v.x), .y = @intFromFloat(v.y) };
    }
};
