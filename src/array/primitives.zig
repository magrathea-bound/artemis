//! Arrow Arrays
const std = @import("std");
const Io = std.Io;
const u = @import("utils.zig");

///Comptime function to define Fixed buffer types
pub fn FixedBuffer(comptime T: type) type {
    return struct {
        length: usize,
        nulls: usize, 
        values: []T,
        null_bitmap: []u8,
        alloc: std.mem.Allocator,

        const Self = @This();

        fn load(source: []const ?T, fb: *Self) void {
            for (source, fb.length..) |src, i| {
                if (src) |val| {
                    fb.values[i] = val;
                } else {
                    fb.values[i] = 0;
                    const elem = i / 8;
                    const bit = i % 8;
                    fb.null_bitmap[elem] |= @as(u8, 1) << @intCast(bit);
                    fb.nulls += 1;
                }
            }
            fb.length += source.len;
        } 

        pub fn init(alloc: std.mem.Allocator, source: []const ?T) !Self {
            var fb = Self {
                .length = 0,
                .nulls = 0,
                .values = undefined,
                .null_bitmap = undefined,
                .alloc = alloc
            };
            const data_bytes = @sizeOf(T) * source.len;
            const target_cap = u.calc_cap(data_bytes);
            const allocated_elements = target_cap / @sizeOf(T);
            fb.values = try alloc.alloc(T, allocated_elements);   

            const null_bytes = (source.len + 7) / 8;
            const null_cap = u.calc_cap(null_bytes);
            fb.null_bitmap = try alloc.alloc(u8, null_cap);

            load(source, &fb);

            return fb;
        }

        pub fn deinit(self: @This()) void {
            self.alloc.free(self.values);
            self.alloc.free(self.null_bitmap);
        }

    };
}

const UInt8 = FixedBuffer(u8);
const UInt16 = FixedBuffer(u16);
const UInt32 = FixedBuffer(u32);
const UInt64 = FixedBuffer(u64);
const Int8 = FixedBuffer(i8);
const Int16 = FixedBuffer(i16);
const Int32 = FixedBuffer(i32);
const Int64 = FixedBuffer(i64);
const Float16 = FixedBuffer(f16);
const Float32 = FixedBuffer(f32);
const Float64 = FixedBuffer(f64);


test "unsigned fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?u8 = &[_]?u8{1, 2, null, 42, 8};
    const array = try UInt8.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values.len == 64);
    try std.testing.expect(array.values[0] == 1);
    try std.testing.expect(array.values[4] == 8);
}

test "signed fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?i16 = &[_]?i16{1, 2, null, 42, 8};
    const array = try Int16.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values.len == 32);
    try std.testing.expect(array.values[0] == 1);
    try std.testing.expect(array.values[4] == 8);
}

test "float fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?f32 = &[_]?f32{1.0, 3.14, null, 42.8, 8.92};
    const array = try Float32.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values.len == 16);
    try std.testing.expect(array.values[0] == 1.0);
    try std.testing.expect(array.values[4] == 8.92);
}

