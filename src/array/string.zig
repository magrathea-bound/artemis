//! Arrow Arrays
const std = @import("std");
const Io = std.Io;

//TODO: implement retrieve value function
const String = struct {
    length: usize,
    nulls: usize,
    offset: []u32,
    values: []u8,

    const Self = @This();

    fn calc_cap(bytes: usize) usize {
        var capacity: usize = 64;
        while (capacity < bytes) {
            capacity *= 2;
        }
        return capacity;
    }

    
    //TODO: increase size to u64 in case of extra long string
    ///Init from a slice of slices
    ///Assumption: length of total char < u32
    pub fn init(alloc: std.mem.Allocator, source: []const ?[]const u8) !String {
        const offset_cap = calc_cap(2*(source.len+1));
        const offset: []u32 = try alloc.alloc(u32, offset_cap/2);
        offset[0] = 0;

        var nulls: usize = 0;
        var len: u32 = 0;
        for (source, 1..) |str, i| {
            const s = str orelse {
                nulls += 1;
                offset[i] = len;
                continue;
            };

            len += @intCast(s.len);
            offset[i] = len;
        }

        const target_len: usize = calc_cap(len);
        const target: []u8 = try alloc.alloc(u8, target_len);

        for (source, 0..) |str, i| {
            const s = str orelse continue;
            const start: u32 = offset[i];
            const end: u32 = offset[i+1];
            @memcpy(target[start..end], s);
        }

        return .{
            .length = source.len,
            .nulls = nulls,
            .offset = offset,
            .values = target,
        };



    }


};

test "string" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?[]const u8 = &[_]?[]const u8{"Hello", "world", "testing", null, "dog", "cat"};
    const array = try String.init(alloc, source);
    defer alloc.free(array.values);
    defer alloc.free(array.offset);

    try std.testing.expect(array.length == 6);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.offset[1] == 5);
    try std.testing.expect(array.offset[6] - array.offset[5] == 3);

    const item5_start = array.offset[5];
    const item5_end = array.offset[6];
    try std.testing.expect(std.mem.eql(u8, array.values[item5_start..item5_end], "cat"));

    // try std.testing.expect(std.mem.eql(u8,
    //         array.values[item5_start..item5_end],
    //         "dog"));
}

