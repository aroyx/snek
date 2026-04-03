//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const sdl = @import("sdl3");

const max_fps = 60;
const window_width = 720;
const window_height = 480;

pub fn run() !void {
    defer sdl.shutdown();

    const init_flags = sdl.InitFlags{ .video = true };
    try sdl.init(init_flags);
    defer sdl.quit(init_flags);

    const window = try sdl.video.Window.init("Snek", window_width, window_height, .{});
    defer window.deinit();

    var fps_capper = sdl.extras.FramerateCapper(f32){ .mode = .{ .limited = max_fps } };

    var quit = false;
    while (!quit) {
        // const dt = fps_capper.delay();
        _ = fps_capper.delay();

        const surface = try window.getSurface();
        try surface.fillRect(null, surface.mapRgb(90, 150, 230));
        try window.updateSurface();

        while (sdl.events.poll()) |event|
            switch (event) {
                .quit, .terminating => quit = true,
                // .terminating => quit = true,
                else => {},
            };
    }

    std.log.info("Game Starting up!", .{});
}
