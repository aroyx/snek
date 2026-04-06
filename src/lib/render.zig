const sdl = @import("sdl3");
const types = @import("types.zig");
const state = @import("state.zig");

pub fn draw(window: *const sdl.video.Window) !void {
    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(90, 150, 230));

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
    try surface.fillRect(rect, surface.mapRgb(100, 255, 80));

    // try draw_tails(window);

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

// fn draw_tails(window: *const sdl.video.Window) !void {
//     const surface = try window.getSurface();
//     const tl = state.snek.TailLength;
//     const body = &state.snek.Body;
//
//     const renderer = try sdl.render.getRenderer(window);
//     renderer.setDrawColor(.{ .a = 255, .r = 100, .g = 255, .b = 80 });
//
//     var i: u32 = 0;
//     while (i < tl - 1) {
//         const rect: sdl.rect.IRect = .{
//             .x = body[i].Pos.x,
//             .y = body[i].Pos.y,
//             .h = 40,
//             .w = 40,
//         };
//
//         try surface.fillRect(rect, surface.mapRgb(100, 255, 80));
//         i += 1;
//     }
//
//     const rect: sdl.rect.IRect = .{
//         .x = body[tl].Pos.x,
//         .y = body[tl].Pos.y,
//         .h = 40,
//         .w = 40,
//     };
//
//     try surface.fillRect(rect, surface.mapRgb(100, 255, 80));
// }
