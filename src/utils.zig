const std = @import("std");
const C = @import("c.zig").C;

pub fn exit(msg: [*c]const u8) void {
    C.TraceLog(
        C.LOG_ERROR,
        msg,
    );

    std.process.exit(1);
}
