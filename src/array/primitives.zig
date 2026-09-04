//! Arrow Arrays
const std = @import("std");
const Io = std.Io;


//TODO: Add null array (Or debate if leaving values as null is better)
//TODO: Add 128 byte buffers, only needed for i and f?
//TODO: Append function
//TODO: Remove function
//TODO: Stream function?
//TODO: Add non null primitives; @typeInfo(T) == .optional;
///Comptime function to define Fixed buffer types
pub fn FixedBuffer(comptime T: type) type {
    return struct {
        length: usize,
        nulls: usize, 
        values: []T,
        alloc: std.mem.Allocator,

        const Self = @This();

        ///Loops to find the 64 byte alignment size for a fixed buffer
        fn calc_cap(bytes: usize) usize {
            var capacity: usize = 8;
            while (capacity < bytes) {
                capacity *= 2;
            }
            return capacity;
        }

        ///Count the nulls within the slice
        ///This will likely be replaced when null array is implemented
        fn count_nulls(buffer: []const T) usize {
            var i: usize = 0;
            for (buffer) |item| {
                if(item == null) {
                    i+=1;
                }
            }
            return i;
        }

        pub fn init(alloc: std.mem.Allocator, source: []const T) !Self {
            const data_bytes = @sizeOf(T) * source.len;
            const target_cap = Self.calc_cap(data_bytes);
            const allocated_elements = target_cap / @sizeOf(T);
            const dest: []T = try alloc.alloc(T, allocated_elements);   

            const nulls = count_nulls(source);

            @memcpy(dest[0..source.len], source);

            return .{
                .length = source.len,
                .nulls = nulls,
                .values = dest,
                .alloc = alloc,
            };
        }

        pub fn deinit(self: @This()) void {
            self.alloc.free(self.values);
        }

    };
}

const UInt8 = FixedBuffer(?u8);
const UInt16 = FixedBuffer(?u16);
const UInt32 = FixedBuffer(?u32);
const UInt64 = FixedBuffer(?u64);
const Int8 = FixedBuffer(?i8);
const Int16 = FixedBuffer(?i16);
const Int32 = FixedBuffer(?i32);
const Int64 = FixedBuffer(?i64);
const Float16 = FixedBuffer(?f16);
const Float32 = FixedBuffer(?f32);
const Float64 = FixedBuffer(?f64);


test "unsigned fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?u8 = &[_]?u8{1, 2, null, 42, 8};
    const array = try UInt8.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values.len == 8);
    try std.testing.expect(array.values[0] == 1);
    try std.testing.expect(array.values[4] == 8);
}

test "signed fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?i8 = &[_]?i8{1, 2, null, 42, 8};
    const array = try Int8.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values[0] == 1);
    try std.testing.expect(array.values[4] == 8);
}

test "float fixedbuffer" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?f16 = &[_]?f16{1.0, 3.14, null, 42.8, 8.92};
    const array = try Float16.init(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 5);
    try std.testing.expect(array.nulls == 1);
    try std.testing.expect(array.values[0] == 1.0);
    try std.testing.expect(array.values[4] == 8.92);
}

