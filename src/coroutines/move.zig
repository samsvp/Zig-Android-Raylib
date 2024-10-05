const std = @import("std");
const Index = @import("../components/index.zig").Index;
const Input = @import("../systems/input.zig").Input;
const Position = @import("../components/position.zig").Position;
const Board = @import("../systems/board.zig").Board;
const Character = @import("../systems/board.zig").Character;
const Cor = @import("../systems/coroutine.zig");

pub const MoveCoroutine = struct {
    target_index: Index,
    target_position: Position,
    char: Character,
    cb_routines: std.ArrayList(Cor.Coroutine),
    input: *Input,

    pub fn init(
        board: *Board,
        target_index: Index,
        char: Character,
        cb_routines: std.ArrayList(Cor.Coroutine),
        input: *Input,
    ) MoveCoroutine {
        switch (char) {
            inline else => |c| {
                c.*.position = board.posFromIndex(c.*.index).?;
                c.*.index = .{ .x = board.columns, .y = board.rows };
            },
        }

        const target_position = board.posFromIndex(target_index).?;
        input.lock += 1;
        return .{
            .target_index = target_index,
            .target_position = target_position,
            .char = char,
            .cb_routines = cb_routines,
            .input = input,
        };
    }

    pub fn move(self: *MoveCoroutine, dt: f32) bool {
        switch (self.char) {
            inline else => |c| {
                const dx = self.target_position.x - c.*.position.x;
                const dy = self.target_position.y - c.*.position.y;
                const move_direction = .{
                    .x = dx * dx / (dx * dx + dy * dy),
                    .y = dy * dy / (dx * dx + dy * dy),
                };
                const speed = 1000.0;
                c.*.position.x += std.math.sign(dx) * move_direction.x * dt * speed;
                c.*.position.y += std.math.sign(dy) * move_direction.y * dt * speed;

                const delta = @abs(dx) + @abs(dy);
                if (delta < 10.0) {
                    c.*.index = self.target_index;
                    c.*.position = self.target_position;
                    self.input.lock -= 1;
                    for (self.cb_routines.items) |routine| {
                        Cor.global_runner.add(routine);
                    }
                    self.cb_routines.deinit();
                    std.heap.c_allocator.destroy(self);
                    return true;
                }
                return false;
            },
        }
    }
};
