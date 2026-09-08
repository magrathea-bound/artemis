const std = @import("std");
const u = @import("utils.zig");

const Bool = struct {
    length: usize,
    nulls: usize,
    values: []u8,
    null_bitmap: []u8,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn load(source: []const ?bool, b: *Bool) void {
        for (source, 0..) |val, i| {
            const elem = i / 8;
            const bit: u3 = @intCast(i % 8);

            if (val) |v| {
                switch (v) {
                    true => {
                        b.values[elem] |= @as(u8, 1) << bit;
                    },
                    else => continue,
                }
            } else {
                b.null_bitmap[elem] |= @as(u8, 1) << bit;
                b.nulls += 1;
            }
        }
        b.length += source.len;
    }

    pub fn init(alloc: std.mem.Allocator, source: []const ?bool) !Self {
        var b = Self{
            .length = 0,
            .nulls = 0,
            .values = undefined,
            .null_bitmap = undefined,
            .alloc = alloc,
        };

        const bytes_req = (source.len + 7) / 8;
        const buf_cap = u.calc_cap(bytes_req);
        b.values = try alloc.alloc(u8, buf_cap);
        @memset(b.values, 0);
        b.null_bitmap = try alloc.alloc(u8, buf_cap);
        @memset(b.null_bitmap, 0);

        load(source, &b);

        return b;
        }
        
    pub fn deinit(self: Self) void {
        self.alloc.free(self.values);
        self.alloc.free(self.null_bitmap);
    }

};


test "boolean" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?bool = &[_]?bool{true, false, null, false, true};
    const array = try Bool.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.null_bitmap.len == 64);
    try std.testing.expect(array.null_bitmap[0] == 0b0000_0100);
    try std.testing.expect(array.values.len == 64);
    try std.testing.expect(array.values[0] == 0b0001_0001);
}

