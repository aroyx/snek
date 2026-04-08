const sdl = @import("sdl3");
const std = @import("std");
const types = @import("types.zig");
const state = @import("state.zig");

pub fn draw(renderer: *const sdl.render.Renderer) !void {
    try renderer.setDrawColor(.{ .r = 100, .g = 255, .b = 80, .a = 255 });
    try renderer.clear();

    try draw_grid(renderer);

    // draw food
    const food_wid = 30.0;
    const food_x = state.food.x + (types.grid_size - food_wid) / 2.0;
    const food_y = state.food.y + (types.grid_size - food_wid) / 2.0;

    const rect_food: sdl.rect.Rect(f32) = .{
        .x = food_x,
        .y = food_y,
        .h = food_wid,
        .w = food_wid,
    };

    try renderer.setDrawColor(.{ .r = 255, .g = 25, .b = 40, .a = 255 });
    try renderer.renderFillRect(rect_food);

    // draw snake
    const rect: sdl.rect.Rect(f32) = .{
        .x = state.snek.Pos.x,
        .y = state.snek.Pos.y,
        .h = 38.0,
        .w = 38.0,
    };

    try renderer.setDrawColor(.{ .r = 91, .g = 123, .b = 249, .a = 255 });
    try renderer.renderFillRect(rect);

    // try draw_tails(renderer);

    try renderer.present();
}

fn draw_grid(renderer: *const sdl.render.Renderer) !void {
    var row: f32 = 0;

    try renderer.setDrawColor(.{ .r = 255, .g = 255, .b = 255, .a = 255 });

    const width = @as(f32, @floatFromInt(types.width));
    const win_dim = @as(f32, @floatFromInt(types.win_dim));
    while (row <= types.win_dim) {
        const rect: sdl.rect.Rect(f32) = .{
            .x = row - (width / 2.0),
            .y = 0,
            .h = win_dim,
            .w = width,
        };
        try renderer.renderFillRect(rect);

        const recth: sdl.rect.Rect(f32) = .{
            .x = 0.0,
            .y = row - (width / 2.0),
            .h = width,
            .w = win_dim,
        };
        try renderer.renderFillRect(recth);

        row += types.grid_size;
    }
}

// fn draw_tails(renderer: *const sdl.render.Renderer) !void {
//     const tl = state.snek.TailLength;
//     const path = &state.snek.Path;
//     const tail_colour: sdl.pixels.Color = .{ .a = 255, .r = 100, .g = 143, .b = 249 };
//
//     var i: u8 = state.path_index -% 2;
//     var segments_drawn: u8 = 0;
//
//     const arc_iter = 5;
//     _ = arc_iter;
//
//     var left_points: std.ArrayList(sdl.render.Vertex) = .empty;
//     var right_points: std.ArrayList(sdl.render.Vertex) = .empty;
//
//     while (segments_drawn < tl) : (segments_drawn += 1) {
//         const node = path[i];
//
//         switch (node.Shape) {
//             .Vertical => {},
//             .Horizontal => {},
//             .TopRight => {},
//             .TopLeft => {},
//             .BottomRight => {},
//             .BottomLeft => {},
//         }
//
//         // const rect: sdl.rect.Rect(f32) = .{
//         //     .x = node.Pos.x,
//         //     .y = node.Pos.y,
//         //     .h = 38.0,
//         //     .w = 38.0,
//         // };
//
//         i = i -% 1;
//     }
//
//     const vertices = right_points + left_points;
//     try renderer.setDrawColor(tail_colour);
//     try renderer.renderGeometry(null, vertices.items, null);
// }
