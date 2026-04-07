//! This file stores the global state of the project!

const std = @import("std");
const types = @import("types.zig");
const fs = std.fs;

pub var snek: types.Snake = .{
    .Pos = .{
        .x = 0,
        .y = 0,
    },
    .Score = 0,
    .Dir = types.Direction.East,
    .TailLength = 0,
    .Path = undefined,
};

pub var food: types.Vec2 = .{
    .x = 0,
    .y = 0,
};

pub var requested_dir: types.Direction = types.Direction.East;
pub var dir_change = false;
pub var rand: std.Random = undefined;
pub var quit: bool = false;
pub var path_index: u8 = 0;

const Data = struct {
    highscore: u32,
    deaths: u32,
};

pub var Global: Data = .{
    .highscore = 0,
    .deaths = 0,
};

pub fn read_data(p_Path: []const u8) !void {
    var buf: [256]u8 = undefined;
    var buf2: [256]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const allocator = fba.allocator();

    const working_dir = try fs.getAppDataDir(allocator, "snek");
    const path = try std.fmt.bufPrint(&buf2, "{s}/{s}", .{ working_dir, p_Path });

    defer allocator.free(working_dir);

    // std.debug.print("{s}\n", .{path});

    const file = fs.openFileAbsolute(path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.info("We couldn't find any data files, perhaps you are running this for the first time. Don't worry, we'll create a file for you! :) <3", .{});
            return;
        },
        else => return err,
    };

    defer file.close();

    // https://cookbook.ziglang.cc/01-01-read-file-line-by-line/
    var buf3: [16]u8 = undefined;
    var reader = file.reader(&buf3);

    const highscore_line = try reader.interface.takeDelimiter('\n');
    const death_line = try reader.interface.takeDelimiter('\n');

    Global.highscore = try std.fmt.parseInt(u32, highscore_line.?, 10);
    Global.deaths = try std.fmt.parseInt(u32, death_line.?, 10);
}

pub fn save_data(p_Path: []const u8) !void {
    var buf: [256]u8 = undefined;
    var buf2: [256]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const allocator = fba.allocator();
    const working_dir = try fs.getAppDataDir(allocator, "snek");
    const path = try std.fmt.bufPrint(&buf2, "{s}/{s}", .{ working_dir, p_Path });

    defer allocator.free(working_dir);

    fs.makeDirAbsolute(working_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {}, // all good :)
        else => return err,
    };

    const file = try fs.createFileAbsolute(path, .{ .read = true });
    defer file.close();

    var ioBuffer: [16]u8 = undefined;
    var file_writer = file.writer(&ioBuffer);
    var writer = &file_writer.interface;

    try writer.print("{d}\n", .{Global.highscore});
    try writer.print("{d}\n", .{Global.deaths});
    try writer.flush();
}


