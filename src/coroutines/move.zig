const std = @import("std");
const Index = @import("../components/index.zig").Index;
const Input = @import("../systems/input.zig").Input;
const Position = @import("../components/position.zig").Position;
const Board = @import("../systems/board.zig").Board;
const Character = @import("../systems/board.zig").Character;
const Cor = @import("../systems/coroutine.zig");

pub const MoveCoroutine = struct {
    target_index: ?Index,
    target_position: Position,
    char: Character,
    cb_routines: std.ArrayList(Cor.Coroutine),
    input: *Input,
    had_err: bool,
    max_time: f32 = 1.0,
    current_time: f32 = 0.0,

    pub fn init(
        board: *Board,
        target_index: ?Index,
        target_position: Position,
        char: Character,
        cb_routines: std.ArrayList(Cor.Coroutine),
        input: *Input,
    ) MoveCoroutine {
        var had_err = false;
        switch (char) {
            inline else => |c| {
                c.*.position = board.posFromIndex(c.*.index) orelse blk: {
                    had_err = true;
                    break :blk c.*.position;
                };
                if (!had_err) {
                    c.*.index = .{ .x = board.columns, .y = board.rows };
                    input.addLock();
                }
            },
        }

        return .{
            .target_index = target_index,
            .target_position = target_position,
            .char = char,
            .cb_routines = cb_routines,
            .input = input,
            .had_err = had_err,
        };
    }

    fn finish(self: *MoveCoroutine) void {
        switch (self.char) {
            inline else => |c| {
                if (self.target_index) |t_i| c.*.index = t_i;

                c.*.position = self.target_position;
                self.input.lock_ -= 1;
                for (self.cb_routines.items) |routine| {
                    Cor.global_runner.add(routine);
                }
                self.cb_routines.deinit();
                std.heap.c_allocator.destroy(self);
            },
        }
    }

    pub fn coroutine(self: *MoveCoroutine, dt: f32) bool {
        if (self.had_err) {
            std.debug.print("Movement out \n", .{});
            return true;
        }

        self.current_time += dt;
        if (self.current_time > self.max_time) {
            std.debug.print("movement timeout\n", .{});
            self.finish();
            return true;
        }

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
                    self.finish();
                    return true;
                }
                return false;
            },
        }
    }
};
