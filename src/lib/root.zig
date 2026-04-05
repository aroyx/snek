//! Hehe snek :)
const std = @import("std");
const sdl = @import("sdl3");
const state = @import("state.zig");

const data_path = "data.txt";
const max_fps = 60;
const window_width = 720;
const window_height = 480;

pub fn run() !void {
    std.log.info("Game Starting up!", .{});

    try state.read_data(data_path);

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
                else => {},
            };
    }

    // std.debug.print("Highscore: {d}\n", .{state.Global.highscore});
    // std.debug.print("Deaths: {d}\n", .{state.Global.deaths});

    try state.save_data(data_path);
}
