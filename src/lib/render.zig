const sdl = @import("sdl3");
const std = @import("std");
const types = @import("types.zig");
const state = @import("state.zig");

var food_tex: sdl.render.Texture = undefined;
var snek_tex: sdl.render.Texture = undefined;

pub fn init_textures(renderer: *const sdl.render.Renderer) !void {
    const food_sur = try sdl.image.loadPngIo(try .initFromFile("res/food.png", .read_binary));
    const snek_sur = try sdl.image.loadPngIo(try .initFromFile("res/snek.png", .read_binary));

    food_tex = try renderer.createTextureFromSurface(food_sur);
    snek_tex = try renderer.createTextureFromSurface(snek_sur);

    defer food_sur.deinit(); // why do I have defer here...
    defer snek_sur.deinit();
}

pub fn deinit_textures() void {
    _ = food_tex.deinit();
    _ = snek_tex.deinit();
}

pub fn draw(allocator: std.mem.Allocator, renderer: *const sdl.render.Renderer) !void {
    try renderer.setDrawColor(.{ .r = 100, .g = 255, .b = 80, .a = 255 });
    try renderer.clear();

    try draw_grid(renderer);

    // draw food
    const rect_food: sdl.rect.Rect(f32) = .{
        .x = state.food.x,
        .y = state.food.y,
        .h = types.grid_size,
        .w = types.grid_size,
    };

    try renderer.renderTexture(food_tex, null, rect_food);

    if (state.snek.TailLength > 0) {
        try draw_tails(allocator, renderer);
    }

    // draw snake
    const rect: sdl.rect.Rect(f32) = .{
        .x = state.snek.Pos.x,
        .y = state.snek.Pos.y,
        .h = types.grid_size,
        .w = types.grid_size,
    };

    switch (state.snek.Dir) {
        .East => {
            try renderer.renderTextureRotated(snek_tex, null, rect, 90.0, null, .{});
        },
        .West => {
            try renderer.renderTextureRotated(snek_tex, null, rect, 270.0, null, .{});
        },
        .North => {
            try renderer.renderTexture(snek_tex, null, rect);
        },
        .South => {
            try renderer.renderTextureRotated(snek_tex, null, rect, 180.0, null, .{});
        },
    }

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

const tail_colour: sdl.pixels.FColor = .{ .a = 1.0, .r = 100.0 / 255.0, .g = 143.0 / 255.0, .b = 249.0 / 255.0 };
var snake_width: f32 = types.grid_size - 2.0;

fn draw_tails(allocator: std.mem.Allocator, renderer: *const sdl.render.Renderer) !void {
    const tl = state.snek.TailLength;
    const path = &state.snek.Path;

    var i: u8 = state.path_index -% 1;
    var segments_drawn: u8 = 0;

    const arc_iter = 5;

    var vertices: std.ArrayList(sdl.render.Vertex) = .empty;
    defer vertices.deinit(allocator);

    // while (segments_drawn < tl + 1) : (segments_drawn += 1) {
    while (segments_drawn < tl) : (segments_drawn += 1) {
        const percent_drawn = @as(f32, @floatFromInt(tl - segments_drawn)) / @as(f32, @floatFromInt(tl));
        const min_width = types.grid_size / 3.0;
        const max_width = types.grid_size - 4.0;

        snake_width = min_width + (max_width - min_width) * percent_drawn;

        const node = path[i];

        switch (node.Shape) {
            .Vertical => {
                const y = node.Pos.y + (types.grid_size / 2.0);
                const w = (types.grid_size - snake_width) / 2.0;

                const vertex_l: sdl.render.Vertex = .{
                    .tex_coord = undefined,
                    .color = tail_colour,
                    .position = .{ .x = node.Pos.x + w, .y = y },
                };

                const vertex_r: sdl.render.Vertex = .{
                    .tex_coord = undefined,
                    .color = tail_colour,
                    .position = .{ .x = node.Pos.x + types.grid_size - w, .y = y },
                };

                try vertices.append(allocator, vertex_l);
                try vertices.append(allocator, vertex_r);
            },
            .Horizontal => {
                const x = node.Pos.x + (types.grid_size / 2.0);
                const h = (types.grid_size - snake_width) / 2.0;

                const vertex_l: sdl.render.Vertex = .{
                    .tex_coord = undefined,
                    .color = tail_colour,
                    .position = .{ .x = x, .y = node.Pos.y + h },
                };

                const vertex_r: sdl.render.Vertex = .{
                    .tex_coord = undefined,
                    .color = tail_colour,
                    .position = .{ .x = x, .y = node.Pos.y + (types.grid_size) - h },
                };

                try vertices.append(allocator, vertex_l);
                try vertices.append(allocator, vertex_r);
            },
            .TopRight => {
                try add_arc(.{
                    .deg = 90.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = 0.0, .y = 0.0 },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .TopLeft => {
                try add_arc(.{
                    .deg = 0.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = 0.0, .y = types.grid_size },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .BottomRight => {
                try add_arc(.{
                    .deg = 180.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = types.grid_size, .y = 0.0 },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .BottomLeft => {
                try add_arc(.{
                    .deg = 270.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = types.grid_size, .y = types.grid_size },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
        }

        i = i -% 1;
    }

    // { // tail -> the last one
    //     const tail_node = path[i +% 1];
    //     const y = tail_node.Pos.y + (types.grid_size / 2.0);
    //     const w = (types.grid_size - snake_width) / 2.0;
    //
    //     const vertex_l: sdl.render.Vertex = .{
    //         .tex_coord = undefined,
    //         .color = tail_colour,
    //         .position = .{ .x = tail_node.Pos.x + w, .y = y },
    //     };
    //
    //     const vertex_r: sdl.render.Vertex = .{
    //         .tex_coord = undefined,
    //         .color = tail_colour,
    //         .position = .{ .x = tail_node.Pos.x + types.grid_size - w, .y = y },
    //     };
    //
    //     const vertex_k: sdl.render.Vertex = .{
    //         .tex_coord = undefined,
    //         .color = tail_colour,
    //         .position = .{ .x = tail_node.Pos.x + (types.grid_size / 2.0), .y = y },
    //     };
    //
    //     try vertices.append(allocator, vertex_l);
    //     try vertices.append(allocator, vertex_r);
    //     try vertices.append(allocator, vertex_k);
    // }

    if (vertices.items.len > 0) {
        try renderer.setDrawColor(.{ .a = 255, .b = 255, .g = 255, .r = 255 });
        var indices: std.ArrayList(c_int) = .empty;
        defer indices.deinit(allocator);

        for (0..(vertices.items.len - 2)) |j| {
            const k = @as(c_int, @intCast(j));
            try indices.append(allocator, k);
            try indices.append(allocator, k + 1);
            try indices.append(allocator, k + 2);
        }

        try renderer.renderGeometry(null, vertices.items, indices.items);
    }
}

const arc_params = struct {
    iterations: u8 = 0,
    deg: f32 = 0,
    pos: types.Vec2,
    translate: types.Vec2,
    allocator: std.mem.Allocator = undefined,
    arr: *std.ArrayList(sdl.render.Vertex),
};

fn add_arc(a: arc_params) !void {
    var vertex: sdl.render.Vertex = .{
        .position = .{ .x = 0, .y = 0 },
        .color = tail_colour,
        .tex_coord = undefined,
    };

    for (0..a.iterations + 1) |i| {
        const r = (types.grid_size - snake_width) / 2.0;
        const R = r + snake_width;

        const theta = std.math.degreesToRadians(a.deg +
            (90.0 / @as(f32, @floatFromInt(a.iterations))) *
                @as(f32, @floatFromInt(i)));

        vertex.position.x = (r * @cos(theta)) + a.pos.x + a.translate.x;
        vertex.position.y = (r * @sin(theta)) + a.pos.y + a.translate.y;
        try a.arr.append(a.allocator, vertex);

        vertex.position.x = (R * @cos(theta)) + a.pos.x + a.translate.x;
        vertex.position.y = (R * @sin(theta)) + a.pos.y + a.translate.y;
        try a.arr.append(a.allocator, vertex);
    }
}
