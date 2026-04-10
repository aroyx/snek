pub const max_fps = 60;
pub const win_dim = 720;
pub const grid_size = 40.0;
pub const width = 2;
pub const max_body_len = 256;

pub const Direction = enum { North, South, East, West };
pub const Vec2 = struct { x: f32, y: f32 };

pub const Snake = struct {
    Pos: Vec2,
    Score: u32,
    Dir: Direction,
    HeadAngle: f32,

    Path: [max_body_len]PathNode,
    TailLength: u8,
};

pub const PathNode = struct {
    Shape: SegmentShape,
    Pos: Vec2,
};

pub const SegmentShape = enum {
    Vertical,
    Horizontal,
    TopRight,
    TopLeft,
    BottomRight,
    BottomLeft,
};

