const sdl = @import("sdl3");
const types = @import("types.zig");
const state = @import("state.zig");

pub fn draw(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(100, 255, 80));

    try draw_grid(window);

    // draw food
    const food_wid = 30.0;
    const food_x = state.food.x + (types.grid_size - food_wid) / 2.0;
    const food_y = state.food.y + (types.grid_size - food_wid) / 2.0;
    const rect_food: sdl.rect.IRect = .{
        .x = @intFromFloat(food_x),
        .y = @intFromFloat(food_y),
        .h = food_wid,
        .w = food_wid,
    };
    try surface.fillRect(rect_food, surface.mapRgb(255, 25, 40));

    // draw snake
    const rect: sdl.rect.IRect = .{
        .x = @intFromFloat(state.snek.Pos.x),
        .y = @intFromFloat(state.snek.Pos.y),
        .h = 38.0,
        .w = 38.0,
    };
    try surface.fillRect(rect, surface.mapRgb(91, 123, 249));

    try draw_tails(window);

    try window.updateSurface();
}

fn draw_grid(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();

    var row: i32 = 0;
    const grid_colour = surface.mapRgb(255, 255, 255);

    while (row <= types.win_dim) {
        const rect: sdl.rect.IRect = .{
            .x = row - (types.width / 2),
            .y = 0,
            .h = types.win_dim,
            .w = types.width,
        };
        try surface.fillRect(rect, grid_colour);

        const recth: sdl.rect.IRect = .{
            .x = 0,
            .y = row - (types.width / 2),
            .h = types.width,
            .w = types.win_dim,
        };
        try surface.fillRect(recth, grid_colour);

        row += types.grid_size;
    }
}

fn draw_tails(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();
    const tl = state.snek.TailLength;
    const path = &state.snek.Path;
    const tail_colour = surface.mapRgb(100, 143, 249);
    var i: u8 = state.path_index -% 2;
    var segments_drawn: u8 = 0;

    while (segments_drawn < tl) : (segments_drawn += 1) {
        const node = path[i];

        const rect: sdl.rect.IRect = .{
            .x = @intFromFloat(node.Pos.x),
            .y = @intFromFloat(node.Pos.y),
            .h = 38,
            .w = 38,
        };

        try surface.fillRect(rect, tail_colour);

        i = i -% 1;
    }
}
