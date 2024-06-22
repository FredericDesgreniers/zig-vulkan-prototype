const std = @import("std");
const glfw = @import("glfw.zig");
const vulkan = @import("vulkan.zig");

pub fn Surface(Inner: type, inner: Inner) type {
    return struct {
        inner: Inner,
        const Self = @This();
        fn init(inner2: Inner) Self {
            return Self{ .inner = inner + inner2 };
        }
    };
}

pub fn main() !void {
    if (!glfw.init()) {
        std.debug.print("Could not init glfw", .{});
    }
    std.debug.print("Init glfw", .{});

    glfw.window_hint();
    defer glfw.terminate();

    const window = glfw.create_window().?;
    defer window.destroy();

    const vulkan_instance = (try vulkan.create_instance(std.heap.c_allocator)).?;
    defer vulkan_instance.destroy();

    const device = (try vulkan_instance.pick_physical_device(std.heap.c_allocator)).?;
    const logical_device = try device.create_logical_device(std.heap.c_allocator);
    defer logical_device.destroy();

    while (!window.should_close()) {
        glfw.poll_events();
    }

    window.destroy();
    glfw.terminate();

    std.debug.print("Exiting", .{});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
