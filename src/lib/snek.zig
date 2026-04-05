const sdl = @import("sdl3");
const std = @import("std");
const max_fps = 60;

const Direction = enum { North, South, East, West };
const vec2 = struct { x: f32, y: f32 };
const Snake = struct { Pos: vec2, Score: u32, Dir: Direction };

var it: f32 = 0.0; // this variable goes from 0..1 every 1 second (see update(dt: f32) function)

const win_dim = 720;
const gap = 40;
const width = 2;

pub var snek: Snake = .{
    .Pos = .{
        .x = 0,
        .y = 0,
    },
    .Score = 0,
    .Dir = Direction.East,
};

pub fn run(window: *const sdl.video.Window) !void {
    var fps_capper = sdl.extras.FramerateCapper(f32){ .mode = .{ .limited = max_fps } };

    var quit = false;
    while (!quit) {
        const dt = fps_capper.delay();

        while (sdl.events.poll()) |event|
            switch (event) {
                .quit, .terminating => quit = true,
                .key_down => |key| if (key.scancode) |scancode| switch (scancode) {
                    .right => snek.Dir = Direction.East,
                    .left => snek.Dir = Direction.West,
                    .up => snek.Dir = Direction.North,
                    .down => snek.Dir = Direction.South,
                    else => {},
                },
                else => {},
            };

        update(dt);
        try draw(window);
    }
}

fn draw(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(90, 150, 230));

    try draw_grid(window);

    // draw snake
    const rect: sdl.rect.IRect = .{
        .x = @intFromFloat(snek.Pos.x),
        .y = @intFromFloat(snek.Pos.y),
        .h = 38.0,
        .w = 38.0,
    };
    try surface.fillRect(rect, surface.mapRgb(255, 25, 40));

    try window.updateSurface();
}

fn draw_grid(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();

    var row: i32 = 0;
    const grid_colour = surface.mapRgb(255, 255, 255);

    while (row <= win_dim) {
        const rect: sdl.rect.IRect = .{
            .x = row - (width / 2),
            .y = 0,
            .h = win_dim,
            .w = width,
        };
        try surface.fillRect(rect, grid_colour);

        const recth: sdl.rect.IRect = .{
            .x = 0,
            .y = row - (width / 2),
            .h = width,
            .w = win_dim,
        };
        try surface.fillRect(recth, grid_colour);

       row += gap;
    }
}

fn update(dt: f32) void {
    it += dt * 60;
    it = @mod(it, 1);

    const factor = dt * 60.0 * 4.0;
    switch (snek.Dir) {
        .East => snek.Pos.x += factor,
        .West => snek.Pos.x -= factor,
        .North => snek.Pos.y -= factor,
        .South => snek.Pos.y += factor,
    }

    // logic to keep the snek grid-locked
    if (snek.Dir == Direction.East or snek.Dir == Direction.West) {
        snek.Pos.y = (@divTrunc(snek.Pos.y, 40) * 40) + (width / 2);
    } else if (snek.Dir == Direction.North or snek.Dir == Direction.South) {
        snek.Pos.x = (@divTrunc(snek.Pos.x, 40) * 40) + (width / 2);
    }

    // todo: wrap the snek around the window
}
