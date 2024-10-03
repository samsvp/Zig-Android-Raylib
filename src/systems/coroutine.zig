/// Coroutines are functions which run every frame. They are single threaded,
/// but are meant to be used when waiting for images or to play animations.
/// Usage:
///    // Initialize global runner:
///    Coroutine.global_runner = Coroutine.CoroutineRunner.init(allocator);
///    defer Coroutine.global_runner.deinit();
///
///    // Add a coroutine
///    const c = Coroutine.Coroutine.init(myStruct, callback);
///    Coroutine.global_runner.add(c);
///
///    // On your main loop, update de coroutines
///    Coroutine.global_runner.update(dt);
const std = @import("std");

pub var global_runner: CoroutineRunner = undefined;

pub const Coroutine = struct {
    context: *anyopaque,
    coroutineFunc: *const fn (*anyopaque, f32) bool,

    pub fn init(context: anytype, coroutineFunc: anytype) Coroutine {
        const T = @TypeOf(context);
        const ptr_info = @typeInfo(T);

        if (ptr_info != .Pointer) {
            @compileError("ptr must be a pointer");
        }
        if (ptr_info.Pointer.size != .One) {
            @compileError("ptr must be a single item pointer");
        }

        const gen = struct {
            pub fn f(pointer: *anyopaque, dt: f32) bool {
                const self: T = @ptrCast(@alignCast(pointer));
                return @call(.auto, coroutineFunc, .{ self, dt });
            }
        };

        return .{
            .context = context,
            .coroutineFunc = gen.f,
        };
    }

    pub fn coroutine(self: Coroutine, dt: f32) bool {
        return self.coroutineFunc(self.context, dt);
    }
};

pub const CoroutineRunner = struct {
    coroutines: std.ArrayList(Coroutine),

    pub fn init(allocator: std.mem.Allocator) CoroutineRunner {
        return .{
            .coroutines = std.ArrayList(Coroutine).init(allocator),
        };
    }

    pub fn deinit(self: *CoroutineRunner) void {
        self.coroutines.deinit();
    }

    pub fn add(self: *CoroutineRunner, coroutine: Coroutine) void {
        self.coroutines.append(coroutine) catch unreachable;
    }

    pub fn remove(self: *CoroutineRunner, index: usize) void {
        _ = self.coroutines.swapRemove(index);
    }

    pub fn update(self: *CoroutineRunner, dt: f32) void {
        var i: usize = 0;
        while (i < self.coroutines.items.len) {
            const finished = self.coroutines.items[i].coroutine(dt);
            if (finished) {
                _ = self.coroutines.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
};
