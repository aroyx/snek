//! This file stores the global state of the project!

const std = @import("std");
const fs = std.fs;

const Data = struct { highscore: u32, deaths: u32 };

pub var Global: Data = .{
    .highscore = 0,
    .deaths = 0,
};

pub fn read_data(p_Path: []const u8) !void {
    var buf: [256]u8 = undefined;
    const working_dir = try fs.getAppDataDir(std.heap.page_allocator, "snek");
    const path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ working_dir, p_Path });

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
    var buf2: [16]u8 = undefined;
    var reader = file.reader(&buf2);

    const highscore_line = try reader.interface.takeDelimiter('\n');
    const death_line = try reader.interface.takeDelimiter('\n');

    Global.highscore = try std.fmt.parseInt(u32, highscore_line.?, 10);
    Global.deaths = try std.fmt.parseInt(u32, death_line.?, 10);
}

pub fn save_data(p_Path: []const u8) !void {
    var buf: [256]u8 = undefined;
    const working_dir = try fs.getAppDataDir(std.heap.page_allocator, "snek");
    const path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ working_dir, p_Path });

    try fs.makeDirAbsolute(working_dir);

    const file = try fs.createFileAbsolute(path, .{ .read = true });
    defer file.close();

    var ioBuffer: [16]u8 = undefined;
    var file_writer = file.writer(&ioBuffer);
    var writer = &file_writer.interface;

    try writer.print("{d}\n", .{Global.highscore});
    try writer.print("{d}\n", .{Global.deaths});
    try writer.flush();
}
