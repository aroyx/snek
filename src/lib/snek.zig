const std = @import("std");
const sdl = @import("sdl3");

const types = @import("types.zig");
const state = @import("state.zig");
const logic = @import("logic.zig");
const render = @import("render.zig");

pub fn run(window: *const sdl.video.Window) !void {
    var fps_capper = sdl.extras.FramerateCapper(f32){ .mode = .{ .limited = types.max_fps } };

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    state.rand = prng.random();

    try logic.drop_the_food();
    while (!state.quit) {
        const dt = fps_capper.delay();

        while (sdl.events.poll()) |event|
            switch (event) {
                .quit, .terminating => state.quit = true,
                .key_down => |key| if (key.scancode) |scancode| switch (scancode) {
                    .right => {
                        if (state.snek.Dir != types.Direction.West) {
                            state.requested_dir = types.Direction.East;
                            state.dir_change = true;
                        }
                    },
                    .left => {
                        if (state.snek.Dir != types.Direction.East) {
                            state.requested_dir = types.Direction.West;
                            state.dir_change = true;
                        }
                    },
                    .up => {
                        if (state.snek.Dir != types.Direction.South) {
                            state.requested_dir = types.Direction.North;
                            state.dir_change = true;
                        }
                    },
                    .down => {
                        if (state.snek.Dir != types.Direction.North) {
                            state.requested_dir = types.Direction.South;
                            state.dir_change = true;
                        }
                    },
                    else => {},
                },
                else => {},
            };

        try logic.update(dt);
        try render.draw(window);
    }
}
