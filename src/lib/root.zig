//! Hehe snek :)
const std = @import("std");
const sdl = @import("sdl3");
const state = @import("state.zig");
const snek = @import("snek.zig");

const data_path = "data.txt";

pub fn run() !void {
    std.log.info("Game Starting up!", .{});

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

    // std.debug.print("Highscore: {d}\n", .{state.Global.highscore});
    // std.debug.print("Deaths: {d}\n", .{state.Global.deaths});

    try state.save_data(data_path);
}
