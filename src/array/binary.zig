//! Arrow Arrays
const std = @import("std");
const Io = std.Io;
const utils = @import("utils.zig");

const Binary = struct {
    length: usize,
    nulls: usize,
    values: []u8,
    offset: []u32,

    const Self = @This();

    fn load_offset(source: []const ?[]const u8, b: *Self) u32 {
        var len: u32 = b.offset[b.length];
        for (source, b.length..) |str, i| {
            const s = str orelse {
                b.nulls += 1;
                b.offset[i+1] = b.offset[i];
                continue;
            };

            len += @intCast(s.len);
            b.offset[i+1] = len;
        }
        return len;
    }

    fn load_values(source: []const ?[]const u8, b: *Self) void {
        for (source, b.length..) |str, i| {
            const s = str orelse continue;
            const start: u32 = b.offset[i];
            const end: u32 = b.offset[i+1];
            @memcpy(b.values[start..end], s);
        }
        b.length = source.len;
    }

    pub fn init(alloc: std.mem.Allocator, source: []const ?[]const u8) !Self {
        var b = Self{
            .length = 0,
            .nulls = 0,
            .values = undefined,
            .offset = undefined,
        };
        const offset_cap = utils.calc_cap(2*(source.len+1));
        b.offset = try alloc.alloc(u32, offset_cap/2);
        b.offset[0] = 0;

        const offset_len = load_offset(source, &b);

        const target_len: usize = utils.calc_cap(offset_len);
        b.values = try alloc.alloc(u8, target_len);
        load_values(source, &b);

        return b;
    }

};

test "binary" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?[]const u8 = &[_]?[]const u8{"Hello", "world", "testing", null, "dog", "cat"};
    const array = try Binary.init(alloc, source);
    defer alloc.free(array.values);
    defer alloc.free(array.offset);

    try std.testing.expect(array.length == 6);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.offset[1] == 5);
    try std.testing.expect(array.offset[6] - array.offset[5] == 3);

    const item5_start = array.offset[5];
    const item5_end = array.offset[6];
    try std.testing.expect(std.mem.eql(u8, array.values[item5_start..item5_end], "cat"));
}

