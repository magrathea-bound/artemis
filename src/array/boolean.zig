const std = @import("std");
const u = @import("utils.zig");

const Bool = struct {
    length: usize,
    nulls: usize,
    values: u.Bitmap,
    null_bitmap: u.Bitmap,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn load(source: []const ?bool, b: *Bool) void {
        for (source, 0..) |val, i| {
            if (val) |v| {
                //Handle Value
                switch (v) {
                    true => {
                        b.values.load_value(i);
                    },
                    else => continue,
                }
            //Handle Null
            } else {
                b.null_bitmap.load_value(i);
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

        b.values = try u.Bitmap.init(alloc, source.len);
        b.null_bitmap = try u.Bitmap.init(alloc, source.len);

        load(source, &b);

        return b;
        }
        
    pub fn deinit(self: Self) void {
        self.alloc.free(self.values.values);
        self.alloc.free(self.null_bitmap.values);
    }

};


test "boolean" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?bool = &[_]?bool{true, false, null, false, true};
    var array = try Bool.init(alloc, source);
    defer array.deinit();

    //Object allocated properly
    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    //Values match
    try std.testing.expect(array.values.retrieve_val(0));
    try std.testing.expect(!array.values.retrieve_val(1));
    //Nulls Match
    try std.testing.expect(array.null_bitmap.retrieve_val(2));
    try std.testing.expect(!array.null_bitmap.retrieve_val(0));
}

