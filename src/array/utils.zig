const std = @import("std");

pub fn calc_cap(bytes: usize) usize {
    var capacity: usize = 64;
    while (capacity < bytes) {
        capacity *= 2;
    }
    return capacity;
}


pub const Bitmap = struct {
    values: []u8,

    const Self = @This();

    pub fn retrieve_val(self: *Self, elem: usize) bool {
        const i = elem / 8;
        const bit = elem % 8;
        const slice = self.values[i];
        const on: bool = (slice & (@as(u8, 1) << @intCast(bit))) != 0;
        return on;
    }

    pub fn load_array(self: *Self, source: []const bool) void {
        for (source, 0..) |val, i| {
            switch(val) {
                true => {
                    const elem = i / 8;
                    const bit: u3 = @intCast(i % 8);
                    self.values[elem] |= @as(u8, 1) << bit;
                },
                false => continue,
            }
        }
    }

    pub fn load_value(self: *Self, source_index: usize) void {
        const elem = source_index / 8;
        const bit: u3 = @intCast(source_index % 8);
        self.values[elem] |= @as(u8, 1) << bit;
        return; 
    }

    ///Initializes a bitmap
    ///len should be the number of elements tracking not the length of the bitmap
    pub fn init(alloc: std.mem.Allocator, len: usize) !Self {
        var bm = Self{
            .values = undefined,
        };
        var cap = (len * @sizeOf(u8)) / 8;
        cap = calc_cap(cap);
        bm.values = try alloc.alloc(u8, cap);
        @memset(bm.values, 0);
        return bm;
    }
};


test "bitmap" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const data: []const bool = &[_]bool{true, false, true, false, true};
    var array = try Bitmap.init(alloc, data.len);
    defer alloc.free(array.values);
    array.load_array(data);

    try std.testing.expect(array.values.len == 64);
    try std.testing.expect(array.retrieve_val(0));
    try std.testing.expect(!array.retrieve_val(1));

    //try std.testing.expect(array.values[0] == 0b0001_0001);
}
