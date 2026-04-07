const std = @import("std");
const types = @import("types.zig");
const state = @import("state.zig");

pub fn update(dt: f32) !void {
    if (state.dir_change) {
        const tolerance = 4.0;

        if (state.requested_dir == types.Direction.East or state.requested_dir == types.Direction.West) {
            const rem_y = @mod(state.snek.Pos.y, types.grid_size);

            if (rem_y < tolerance or rem_y > types.grid_size - tolerance) {
                state.dir_change = false;
                state.snek.Dir = state.requested_dir;
                state.snek.Pos.y = @round(state.snek.Pos.y / types.grid_size) * types.grid_size + (types.width / 2);
            }
        } else if (state.requested_dir == types.Direction.North or state.requested_dir == types.Direction.South) {
            const rem_x = @mod(state.snek.Pos.x, types.grid_size);

            if (rem_x < tolerance or rem_x > types.grid_size - tolerance) {
                state.dir_change = false;
                state.snek.Dir = state.requested_dir;
                state.snek.Pos.x = @round(state.snek.Pos.x / types.grid_size) * types.grid_size + (types.width / 2);
            }
        }
    }

    const factor = dt * 60.0 * 4.0;
    switch (state.snek.Dir) {
        .East => state.snek.Pos.x += factor,
        .West => state.snek.Pos.x -= factor,
        .North => state.snek.Pos.y -= factor,
        .South => state.snek.Pos.y += factor,
    }

    // snek ate the food.
    const margin = 10.0;
    if (state.snek.Pos.x < state.food.x + types.grid_size - margin and
        state.snek.Pos.x + types.grid_size > state.food.x + margin and
        state.snek.Pos.y < state.food.y + types.grid_size - margin and
        state.snek.Pos.y + types.grid_size > state.food.y + margin)
    {
        try drop_the_food();
        state.snek.Score += 1;
        state.snek.TailLength += 1;
    }

    // snek hit bounds
    if (state.snek.Pos.x < -types.grid_size / 2.0 or
        state.snek.Pos.x > types.win_dim - types.grid_size / 2.0 or
        state.snek.Pos.y < -types.grid_size / 2.0 or
        state.snek.Pos.y > types.win_dim - types.grid_size / 2.0)
    {
        state.quit = true;
    }

    try record_path();
    // todo: wrap the snek around the window
}

pub fn drop_the_food() !void {
    const win_size = 720.0;
    const rand_x = state.rand.float(f32);
    const rand_y = state.rand.float(f32);

    const x = rand_x * win_size;
    const y = rand_y * win_size;

    state.food.x = @floor(x / types.grid_size) * types.grid_size;
    state.food.y = @floor(y / types.grid_size) * types.grid_size;
}

var last_recorded_x: f32 = -100.0;
var last_recorded_y: f32 = -100.0;

fn record_path() !void {
    const current_grid_x = @floor((state.snek.Pos.x + (types.grid_size / 2)) / types.grid_size) * types.grid_size;
    const current_grid_y = @floor((state.snek.Pos.y + (types.grid_size / 2)) / types.grid_size) * types.grid_size;

    if (current_grid_x != last_recorded_x or current_grid_y != last_recorded_y) {
        last_recorded_x = current_grid_x;
        last_recorded_y = current_grid_y;

        var node: types.PathNode = undefined;
        node.Pos.x = current_grid_x;
        node.Pos.y = current_grid_y;

        // determine segment shape
        var last_recorded_dir: types.Direction = types.Direction.East;
        if (last_recorded_dir == state.snek.Dir) {
            switch (state.snek.Dir) {
                .East, .West => node.Shape = types.SegmentShape.Horizontal,
                .North, .South => node.Shape = types.SegmentShape.Vertical,
            }
        } else {
            // this shit is ai generated, I am not doing this shit. Not verifying either
            if ((last_recorded_dir == .East and state.snek.Dir == .North) or
                (last_recorded_dir == .South and state.snek.Dir == .West))
            {
                node.Shape = types.SegmentShape.TopLeft;
            } else if ((last_recorded_dir == .East and state.snek.Dir == .South) or
                (last_recorded_dir == .North and state.snek.Dir == .West))
            {
                node.Shape = types.SegmentShape.BottomLeft;
            } else if ((last_recorded_dir == .West and state.snek.Dir == .North) or
                (last_recorded_dir == .South and state.snek.Dir == .East))
            {
                node.Shape = types.SegmentShape.TopRight;
            } else if ((last_recorded_dir == .West and state.snek.Dir == .South) or
                (last_recorded_dir == .North and state.snek.Dir == .East))
            {
                node.Shape = types.SegmentShape.BottomRight;
            }
        }
        last_recorded_dir = state.snek.Dir;

        state.snek.Path[state.path_index] = node;

        if (state.path_index < 255) {
            state.path_index += 1;
        } else {
            state.path_index = 0;
        }
    }
}
