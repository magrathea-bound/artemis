const std = @import("std");
const u = @import("utils.zig");

const ViewError = error {
    ValueOverflow,
    LengthOverflow,
    IndexOverflow
};
const DEFAULT_BUFFER = 64 * 1024;
const Index = struct {
    bi: u32,
    offset: u32,
};

const Value = struct {
    length: u32,
    buffer: []u8,

    const Self = @This();

    fn load_value(self: *Self, alloc: std.mem.Allocator, s: []const u8) !u32 {
        const src_len: u32 = @intCast(s.len);
        if (self.buffer.len == 0) {
            self.buffer = try alloc.alloc(u8, @max(s.len, DEFAULT_BUFFER));
            @memcpy(self.buffer[0..s.len], s);
            self.length += src_len;
            return @intCast(0);
        }

        if (s.len > self.buffer.len - self.length) {
            return ViewError.ValueOverflow;
        } else {
            const start = self.length;
            const end = start + s.len;
            @memcpy(self.buffer[start..end], s);
            self.length += src_len;
            return @intCast(start);
        }
    }
};

const Values = struct {
    buffers: []Value,

    const Self = @This();

    fn load_value(self: *Self, alloc: std.mem.Allocator, s: []const u8) !Index {
        //Check existing space
        for (self.buffers, 0..) |*buf, i| {
            const offset: u32 = buf.load_value(alloc, s) catch |err| switch (err) {
                ViewError.ValueOverflow => continue,
                else => return err,
            };
            return Index {
                .bi = @intCast(i),
                .offset = offset,
            };

        }

        //Reallocate if needed
        const len = self.buffers.len;
        if (len > std.math.maxInt(u32)) {
            return ViewError.IndexOverflow;
        }
        self.buffers = try alloc.realloc(self.buffers, len * 2);
        const offset: u32 = try self.buffers[len].load_value(alloc, s);        
        return Index {
            .bi = @intCast(len),
            .offset = offset,
        };
    }

    fn init(alloc: std.mem.Allocator) !Self {
        const buffers = try alloc.alloc(Value, 8);
        @memset(buffers, .{
            .length = 0,
            .buffer = &.{},
        });
        return Self {
            .buffers = buffers
        };
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        for (self.buffers) |b| {
            switch (b.buffer.len) {
                0 => continue,
                else => alloc.free(b.buffer),
            }
        }
        alloc.free(self.buffers);
    }
};

const Short = struct {
    length: u32,
    value: [12]u8,

    const Self = @This();

    fn init(source: []const u8) Self {
        var s = Self {
            .length = @intCast(source.len),
            .value = undefined,
        };
        @memset(&s.value, 0);
        @memcpy(s.value[0..source.len], source);
        return s;
    }
};

const Long = struct {
    length: u32,
    prefix: [4]u8,
    index: u32,
    offset: u32,

    const Self = @This();

    fn init(source: []const u8, i: Index) Self {
       var l: Self = Self {
           .length = @intCast(source.len),
           .prefix = undefined,
           .index = i.bi, 
           .offset = i.offset,
       };
       @memcpy(l.prefix[0..], source[0..4]);
       return l;
    }
};

//TODO: View is 20 bytes, why?
const View  = union {
    short: Short,
    long: Long,
};

const BinaryView = struct {
    alloc: std.mem.Allocator,
    length: usize,
    nulls: usize,
    null_bitmap: u.Bitmap, 
    views: []View,
    values: Values,

    const Self = @This();

    fn load_values(self: *Self, source: []const ?[]const u8) !void {
        for (source, self.length..) |str, i| {
            const s = str orelse {
                self.length += 1;
                self.nulls += 1;
                self.null_bitmap.load_value(i);
                continue;
            };
            std.debug.print("String Len: {d}\nString Text:{s}\n", .{s.len, s});
            if (s.len > 12) {
                if (s.len > std.math.maxInt(u32)) {
                    return ViewError.LengthOverflow;
                }
                const ind = try self.values.load_value(self.alloc, s);
                self.views[i] = View {
                    .long = Long.init(s, ind),
                };
                self.length += 1;
            } else {
                self.views[i] = View {
                    .short = Short.init(s),
                };
                self.length += 1;
            }
        }
        return;
    }

    pub fn init_from_array(alloc: std.mem.Allocator, source: []const ?[]const u8) !Self {
        var bv: Self = Self {
            .alloc = alloc,
            .length = 0,
            .nulls = 0,
            .views = undefined,
            .values = undefined,
            .null_bitmap = try u.Bitmap.init(alloc, source.len),
        };

        std.debug.print("sizeofShort {d}\n", .{@sizeOf(Short)});
        std.debug.print("sizeofLong {d}\n", .{@sizeOf(Long)});
        std.debug.print("sizeofView {d}\n", .{@sizeOf(View)});
        const view_cap = u.calc_cap(@sizeOf(View) * source.len);
        bv.views = try alloc.alloc(View, view_cap / @sizeOf(View));

        bv.values = try Values.init(alloc);

        try bv.load_values(source);

        return bv;
    }

    pub fn deinit(self: *Self) void {
        self.alloc.free(self.views);
        self.values.deinit(self.alloc);
        self.alloc.free(self.null_bitmap.values);
        return;
    }


};


test "viewShort" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const source: []const ?[]const u8 = 
        &[_]?[]const u8{"Hello", "world", "gobblewobble", null, "dog", "bumblefuzzle"};
    var array = try BinaryView.init_from_array(alloc, source);
    defer array.deinit();

    try std.testing.expect(array.length == 6);
    try std.testing.expect(array.nulls == 1);
    const view = array.views[5].short;
    try std.testing.expect(view.length == 12);
    try std.testing.expectEqualStrings(&view.value, "bumblefuzzle");
}
