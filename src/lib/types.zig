pub const max_fps = 60;
pub const win_dim = 720;
pub const grid_size = 40.0;
pub const width = 2;

pub const Direction = enum { North, South, East, West };
pub const vec2 = struct { x: f32, y: f32 };
pub const Snake = struct { Pos: vec2, Score: u32, Dir: Direction };
