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

    try renderer.renderTextureRotated(snek_tex, null, rect, state.snek.HeadAngle, null, .{});

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

    var i: u8 = state.path_index -% 2;
    var segments_drawn: u8 = 0;

    const arc_iter = 5;

    var vertices: std.ArrayList(sdl.render.Vertex) = .empty;
    defer vertices.deinit(allocator);

    const sw = types.grid_size - 8.0;

    switch (state.snek.Dir) {
        .East, .West => {
            const x = state.snek.Pos.x + (types.grid_size / 2.0);
            const h = (types.grid_size - sw) / 2.0;

            const vertex_l: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = x, .y = state.snek.Pos.y + h },
            };

            const vertex_r: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = x, .y = state.snek.Pos.y + (types.grid_size) - h },
            };

            try push_pair(&vertices, allocator, vertex_l, vertex_r);
        },
        .North, .South => {
            const y = state.snek.Pos.y + (types.grid_size / 2.0);
            const w = (types.grid_size - sw) / 2.0;

            const vertex_l: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = state.snek.Pos.x + w, .y = y },
            };

            const vertex_r: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = state.snek.Pos.x + types.grid_size - w, .y = y },
            };

            try push_pair(&vertices, allocator, vertex_l, vertex_r);
        },
    }

    while (segments_drawn < tl) : (segments_drawn += 1) {
        const percent_drawn = @as(f32, @floatFromInt(tl - segments_drawn)) / @as(f32, @floatFromInt(tl));
        const min_width = types.grid_size / 3.0;
        const max_width = types.grid_size - 10.0;

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

                try push_pair(&vertices, allocator, vertex_l, vertex_r);
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

                try push_pair(&vertices, allocator, vertex_l, vertex_r);
            },
            .TopRight => {
                try add_arc(.{
                    .deg = 90.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = types.grid_size, .y = 0.0 },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .TopLeft => {
                try add_arc(.{
                    .deg = 0.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = 0.0, .y = 0.0 },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .BottomRight => {
                try add_arc(.{
                    .deg = 180.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = types.grid_size, .y = types.grid_size },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
            .BottomLeft => {
                try add_arc(.{
                    .deg = 270.0,
                    .pos = node.Pos,
                    .iterations = arc_iter,
                    .translate = .{ .x = 0.0, .y = types.grid_size },
                    .allocator = allocator,
                    .arr = &vertices,
                });
            },
        }

        i = i -% 1;
    }

    { // tail -> the last one
        // omfg this took an entire day non-stop. Fuck tis
        const d = switch (state.snek.Dir) {
            .East, .West => @mod(state.snek.Pos.x + (types.grid_size / 2.0), types.grid_size),
            .North, .South => @mod(state.snek.Pos.y + (types.grid_size / 2.0), types.grid_size),
        };

        const da = switch (state.snek.Dir) {
            .East, .South => d,
            .West, .North => if (d == 0.0) 0.0 else types.grid_size - d,
        };

        const tail_node = path[i];
        const next_node = path[i +% 1];

        const diff_x = next_node.Pos.x - tail_node.Pos.x;
        const diff_y = next_node.Pos.y - tail_node.Pos.y;

        var dir_x: f32 = 0.0;
        var dir_y: f32 = 0.0;

        { // this block is generated by ai, I gave it a simple promt with an example.
            if (diff_x > 0 and diff_x <= types.grid_size) dir_x = 1.0;
            if (diff_x < -types.grid_size) dir_x = 1.0;
            if (diff_x < 0 and diff_x >= -types.grid_size) dir_x = -1.0;
            if (diff_x > types.grid_size) dir_x = -1.0;

            if (diff_y > 0 and diff_y <= types.grid_size) dir_y = 1.0;
            if (diff_y < -types.grid_size) dir_y = 1.0;
            if (diff_y < 0 and diff_y >= -types.grid_size) dir_y = -1.0;
            if (diff_y > types.grid_size) dir_y = -1.0;
        }

        const cx = tail_node.Pos.x + (types.grid_size / 2.0) + (dir_x * da);
        const cy = tail_node.Pos.y + (types.grid_size / 2.0) + (dir_y * da);

        const w = (types.grid_size - snake_width) / 2.0;

        if (dir_x != 0.0) {
            const vertex_l: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = cx, .y = tail_node.Pos.y + w },
            };
            const vertex_r: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = cx, .y = tail_node.Pos.y + types.grid_size - w },
            };
            try push_pair(&vertices, allocator, vertex_l, vertex_r);
        } else {
            const vertex_l: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = tail_node.Pos.x + w, .y = cy },
            };
            const vertex_r: sdl.render.Vertex = .{
                .tex_coord = undefined,
                .color = tail_colour,
                .position = .{ .x = tail_node.Pos.x + types.grid_size - w, .y = cy },
            };
            try push_pair(&vertices, allocator, vertex_l, vertex_r);
        }

        const radius = snake_width / 2.0;
        try draw_circle(renderer, allocator, cx, cy, radius);
    }

    if (vertices.items.len > 0) {
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
    var vertex_l: sdl.render.Vertex = .{ .position = undefined, .color = tail_colour, .tex_coord = undefined };
    var vertex_r: sdl.render.Vertex = .{ .position = undefined, .color = tail_colour, .tex_coord = undefined };

    const r = (types.grid_size - snake_width) / 2.0;
    const R = r + snake_width;

    var reverse = false;
    if (a.arr.items.len >= 2) {
        // detect if the arc should be drawn in reverse order
        const last_pos = a.arr.items[a.arr.items.len - 1].position;

        const start_theta = std.math.degreesToRadians(a.deg);
        const end_theta = std.math.degreesToRadians(a.deg + 90.0);

        const start_x = (r * @cos(start_theta)) + a.pos.x + a.translate.x;
        const start_y = (r * @sin(start_theta)) + a.pos.y + a.translate.y;
        const end_x = (r * @cos(end_theta)) + a.pos.x + a.translate.x;
        const end_y = (r * @sin(end_theta)) + a.pos.y + a.translate.y;

        const dist_start = (last_pos.x - start_x) * (last_pos.x - start_x) + (last_pos.y - start_y) * (last_pos.y - start_y);
        const dist_end = (last_pos.x - end_x) * (last_pos.x - end_x) + (last_pos.y - end_y) * (last_pos.y - end_y);

        if (dist_end < dist_start) {
            reverse = true;
        }
    }

    for (0..a.iterations + 1) |i| {
        const step = if (reverse) a.iterations - i else i;

        const theta = std.math.degreesToRadians(a.deg +
            (90.0 / @as(f32, @floatFromInt(a.iterations))) *
                @as(f32, @floatFromInt(step)));

        vertex_l.position.x = (r * @cos(theta)) + a.pos.x + a.translate.x;
        vertex_l.position.y = (r * @sin(theta)) + a.pos.y + a.translate.y;

        vertex_r.position.x = (R * @cos(theta)) + a.pos.x + a.translate.x;
        vertex_r.position.y = (R * @sin(theta)) + a.pos.y + a.translate.y;

        try push_pair(a.arr, a.allocator, vertex_l, vertex_r);
    }
}

/// this function tests for twisting in the drawing array by comparing them to the last two vertices.
fn push_pair(arr: *std.ArrayList(sdl.render.Vertex), alloc: std.mem.Allocator, v1: sdl.render.Vertex, v2: sdl.render.Vertex) !void {
    if (arr.items.len >= 2) {
        const p1 = arr.items[arr.items.len - 2].position;
        const p2 = arr.items[arr.items.len - 1].position;

        // parallets
        const d11 = (p1.x - v1.position.x) * (p1.x - v1.position.x) + (p1.y - v1.position.y) * (p1.y - v1.position.y);
        const d22 = (p2.x - v2.position.x) * (p2.x - v2.position.x) + (p2.y - v2.position.y) * (p2.y - v2.position.y);

        // diagonals
        const d12 = (p1.x - v2.position.x) * (p1.x - v2.position.x) + (p1.y - v2.position.y) * (p1.y - v2.position.y);
        const d21 = (p2.x - v1.position.x) * (p2.x - v1.position.x) + (p2.y - v1.position.y) * (p2.y - v1.position.y);

        if (d12 + d21 < d11 + d22) { // diagonals are shorter than parallels, the mesh is twisting
            try arr.append(alloc, v2);
            try arr.append(alloc, v1);
            return;
        }
    }

    try arr.append(alloc, v1);
    try arr.append(alloc, v2);
}

// this function is unfortunately also AI generated. I'd like to re-do it myself one day. Not today. I am tired today. The end tail took everything from me today.
fn draw_circle(renderer: *const sdl.render.Renderer, allocator: std.mem.Allocator, cx: f32, cy: f32, radius: f32) !void {
    var circle_vertices: std.ArrayList(sdl.render.Vertex) = .empty;
    defer circle_vertices.deinit(allocator);
    var circle_indices: std.ArrayList(c_int) = .empty;
    defer circle_indices.deinit(allocator);

    const segments: usize = 16;

    try circle_vertices.append(allocator, .{ .position = .{ .x = cx, .y = cy }, .color = tail_colour, .tex_coord = undefined });

    for (0..segments + 1) |s| {
        const angle = (@as(f32, @floatFromInt(s)) / @as(f32, @floatFromInt(segments))) * std.math.pi * 2.0;
        try circle_vertices.append(allocator, .{ .position = .{ .x = cx + @cos(angle) * radius, .y = cy + @sin(angle) * radius }, .color = tail_colour, .tex_coord = undefined });
    }

    for (1..segments + 1) |s| {
        try circle_indices.append(allocator, 0);
        try circle_indices.append(allocator, @as(c_int, @intCast(s)));
        try circle_indices.append(allocator, @as(c_int, @intCast(s + 1)));
    }

    try renderer.renderGeometry(null, circle_vertices.items, circle_indices.items);
}
