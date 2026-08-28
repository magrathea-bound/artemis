const std = @import("std");


const Bool = struct {
    length: usize,
    nulls: usize,
    null_buffer: []u8,
    values: []u8,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn calc_cap(bytes: usize) usize {
        var capacity: usize = 8;
        while (capacity < bytes) {
            capacity *= 2;
        }
        return capacity;
    }

    pub fn init(alloc: std.mem.Allocator, source: []const ?bool) !Self {
        //TODO: Potentially subtract nulls from length of buf since they aren't included
        //Thoughts: Works well if i don't skip nulls in target, otherwise
        //it might be better to just separate these two completely...
        //this gets squirrely, how do i handle length?  I think they need to be dealt with 
        //separately
        //length needs to be including nulls though...
        const bytes_req = (source.len + 7) / 8;
        const buf_cap = calc_cap(bytes_req);

        var target: []u8 = try alloc.alloc(u8, buf_cap);
        @memset(target, 0);
        var null_buff: []u8 = try alloc.alloc(u8, buf_cap);
        @memset(null_buff, 0);
        
        var nulls: usize = 0;
        for (source, 0..) |val, i| {
            const elem = i / 8;
            const bit: u3 = @intCast(i % 8);

            if (val) |v| {
                switch (v) {
                    true => {
                        target[elem] |= @as(u8, 1) << bit;
                    },
                    else => continue,
                }
            } else {
                null_buff[elem] |= @as(u8, 1) << bit;
                nulls += 1;
            }
        }
        
        return Self {
            .length = source.len,
            .nulls = nulls,
            .null_buffer = null_buff,
            .values = target,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.values);
        self.alloc.free(self.null_buffer);
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
    try std.testing.expect(array.null_buffer.len == 8);
    try std.testing.expect(array.null_buffer[0] == 0b0000_0100);
    try std.testing.expect(array.values.len == 8);
    try std.testing.expect(array.values[0] == 0b0001_0001);
}

