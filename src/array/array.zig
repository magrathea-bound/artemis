const UInt8 = @import("primitives.zig").UInt8;
const UInt16 = @import("primitives.zig").UInt16;
const UInt32 = @import("primitives.zig").UInt32;
const UInt64 = @import("primitives.zig").UInt64;
const Int8 = @import("primitives.zig").Int8;
const Int16 = @import("primitives.zig").Int16;
const Int32 = @import("primitives.zig").Int32;
const Int64 = @import("primitives.zig").Int64;
const Float16 = @import("primitives.zig").Float16;
const Float32 = @import("primitives.zig").Float32;
const Float64 = @import("primitives.zig").Float64;
const Bool = @import("boolean.zig").Bool;
const String = @import("string.zig").String;


test {
    _ = @import("primitives.zig");
    _ = @import("string.zig");
    _ = @import("boolean.zig");
}
