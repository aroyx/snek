//! Hehe snek :)
const std = @import("std");
const sdl = @import("sdl3");

const state = @import("state.zig");
const snek = @import("snek.zig");

const data_path = "data.txt";

pub fn run() !void {
    try state.read_data(data_path);

    defer sdl.shutdown();

    const init_flags = sdl.InitFlags{ .video = true };
    try sdl.init(init_flags);
    defer sdl.quit(init_flags);

    const win_size = 720;
    const window = try sdl.video.Window.init("Snek", win_size, win_size, .{
        .high_pixel_density = true,
    });
    defer window.deinit();

    try snek.run(&window);

    // update data
    state.Global.deaths += 1;
    if (state.snek.Score > state.Global.highscore) {
        state.Global.highscore = state.snek.Score;
    }

    std.log.info("Score: {d}", .{state.snek.Score});
    std.log.info("Highscore: {d}", .{state.Global.highscore});
    std.log.info("Deaths: {d}", .{state.Global.deaths});

    try state.save_data(data_path);
}
