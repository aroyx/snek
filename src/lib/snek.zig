const sdl = @import("sdl3");
const std = @import("std");
const state = @import("state.zig");
const max_fps = 60;

const Direction = enum { North, South, East, West };
const vec2 = struct { x: f32, y: f32 };
const Snake = struct { Pos: vec2, Score: u32, Dir: Direction };

const win_dim = 720;
const grid_size = 40.0;
const width = 2;

pub var snek: Snake = .{
    .Pos = .{
        .x = 0,
        .y = 0,
    },
    .Score = 0,
    .Dir = Direction.East,
};

var food: vec2 = .{
    .x = 0,
    .y = 0,
};

var requested_dir: Direction = Direction.East;
var dir_change = false;
var rand: std.Random = undefined;

pub fn run(window: *const sdl.video.Window) !void {
    var fps_capper = sdl.extras.FramerateCapper(f32){ .mode = .{ .limited = max_fps } };

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();

    try drop_the_food();
    var quit = false;
    while (!quit) {
        const dt = fps_capper.delay();

        while (sdl.events.poll()) |event|
            switch (event) {
                .quit, .terminating => quit = true,
                .key_down => |key| if (key.scancode) |scancode| switch (scancode) {
                    .right => {
                        if (snek.Dir != Direction.West) {
                            requested_dir = Direction.East;
                            dir_change = true;
                        }
                    },
                    .left => {
                        if (snek.Dir != Direction.East) {
                            requested_dir = Direction.West;
                            dir_change = true;
                        }
                    },
                    .up => {
                        if (snek.Dir != Direction.South) {
                            requested_dir = Direction.North;
                            dir_change = true;
                        }
                    },
                    .down => {
                        if (snek.Dir != Direction.North) {
                            requested_dir = Direction.South;
                            dir_change = true;
                        }
                    },
                    else => {},
                },
                else => {},
            };

        try update(dt);
        try draw(window);
    }
}

fn draw(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(90, 150, 230));

    try draw_grid(window);

    // draw food
    const food_wid = 30.0;
    const food_x = food.x + (grid_size - food_wid) / 2.0;
    const food_y = food.y + (grid_size - food_wid) / 2.0;
    const rect_food: sdl.rect.IRect = .{
        .x = @intFromFloat(food_x),
        .y = @intFromFloat(food_y),
        .h = food_wid,
        .w = food_wid,
    };
    try surface.fillRect(rect_food, surface.mapRgb(255, 25, 40));

    // draw snake
    const rect: sdl.rect.IRect = .{
        .x = @intFromFloat(snek.Pos.x),
        .y = @intFromFloat(snek.Pos.y),
        .h = 38.0,
        .w = 38.0,
    };
    try surface.fillRect(rect, surface.mapRgb(100, 255, 80));

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

        row += grid_size;
    }
}

fn update(dt: f32) !void {
    if (dir_change) {
        const tolerance = 4.0;

        if (requested_dir == Direction.East or requested_dir == Direction.West) {
            const rem_y = @mod(snek.Pos.y, grid_size);

            if (rem_y < tolerance or rem_y > grid_size - tolerance) {
                dir_change = false;
                snek.Dir = requested_dir;
                snek.Pos.y = @round(snek.Pos.y / grid_size) * grid_size + (width / 2);
            }
        } else if (requested_dir == Direction.North or requested_dir == Direction.South) {
            const rem_x = @mod(snek.Pos.x, grid_size);

            if (rem_x < tolerance or rem_x > grid_size - tolerance) {
                dir_change = false;
                snek.Dir = requested_dir;
                snek.Pos.x = @round(snek.Pos.x / grid_size) * grid_size + (width / 2);
            }
        }
    }

    const factor = dt * 60.0 * 4.0;
    switch (snek.Dir) {
        .East => snek.Pos.x += factor,
        .West => snek.Pos.x -= factor,
        .North => snek.Pos.y -= factor,
        .South => snek.Pos.y += factor,
    }

    // snek ate the food.
    const margin = 10.0;
    if (snek.Pos.x < food.x + grid_size - margin and
        snek.Pos.x + grid_size > food.x + margin and
        snek.Pos.y < food.y + grid_size - margin and
        snek.Pos.y + grid_size > food.y + margin)
    {
        try drop_the_food();
        snek.Score += 1;
    }

    // todo: wrap the snek around the window
}

fn drop_the_food() !void {
    const win_size = 720.0;
    const rand_x = rand.float(f32);
    const rand_y = rand.float(f32);

    const x = rand_x * win_size;
    const y = rand_y * win_size;

    food.x = @floor(x / grid_size) * grid_size;
    food.y = @floor(y / grid_size) * grid_size;
}
