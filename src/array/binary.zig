//! Arrow Arrays
const std = @import("std");
const Io = std.Io;
const u = @import("utils.zig");

const Binary = struct {
    alloc: std.mem.Allocator,
    length: usize,
    nulls: usize,
    values: []u8,
    offset: []u32,

    const Self = @This();

    fn load_values(self: *Self, source: []const ?[]const u8) void {
        for (source, self.length..) |str, i| {
            const s = str orelse {
                self.length += 1;
                self.nulls += 1;
                self.offset[i+1] = self.offset[i];
                continue;
        };
            const start = self.offset[i];
            const end = self.offset[i] + s.len;
            self.offset[i+1] = @intCast(end);
            @memcpy(self.values[start..end], s);
            self.length += 1;
        }

        self.length = source.len;
    }

    pub fn init(alloc: std.mem.Allocator, source: []const ?[]const u8) !Self {
        var b = Self{
            .alloc = alloc,
            .length = 0,
            .nulls = 0,
            .values = undefined,
            .offset = undefined,
        };
        const offset_cap = u.calc_cap(@sizeOf(u32) * (source.len+1));
        b.offset = try alloc.alloc(u32, offset_cap / @sizeOf(u32));
        b.offset[0] = 0;

        var buffer_len: usize = 0;
        for (source) |src| {
            const s = src orelse continue;
            buffer_len += s.len;
        } 

        const buf_cap = u.calc_cap(@sizeOf(u8) * buffer_len);
        b.values = try alloc.alloc(u8, buf_cap / @sizeOf(u8));

        b.load_values(source);

        return b;
    }

    pub fn deinit(self: *Self) void {
        self.alloc.free(self.values);
        self.alloc.free(self.offset);
    }

};

test "binary" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?[]const u8 = &[_]?[]const u8{"Hello", "world", "testing", null, "dog", "cat"};
    var array = try Binary.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 6);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.offset[1] == 5);
    try std.testing.expect(array.offset[6] - array.offset[5] == 3);

    const item5_start = array.offset[5];
    const item5_end = array.offset[6];
    try std.testing.expect(std.mem.eql(u8, array.values[item5_start..item5_end], "cat"));
}

