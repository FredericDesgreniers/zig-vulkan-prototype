const std = @import("std");

const glfw = @cImport({
    @cDefine("GLFW_INCLUDE_VULKAN", {});
    @cInclude("glfw3.h");
});

const vulkan = @cImport({
    @cInclude("vulkan/vulkan.h");
});

pub fn init() bool {
    if (glfw.glfwInit() == glfw.GLFW_FALSE) {
        return false;
    } else {
        return true;
    }
}

pub fn window_hint() void {
    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);
}

const WindowPtr = *glfw.struct_GLFWwindow;

pub fn create_window() ?Window {
    if (glfw.glfwCreateWindow(800, 600, "Vulkan", null, null)) |ptr| {
        return Window{
            .ptr = ptr,
        };
    } else {
        return null;
    }
}

pub fn poll_events() void {
    glfw.glfwPollEvents();
}

pub fn terminate() void {
    glfw.glfwTerminate();
}

pub const Extensions = struct {
    count: u32,
    extensions: [][*c]const u8,
};

pub fn getExtensions(allocator: std.mem.Allocator) !Extensions {
    var count: u32 = 0;
    const extensions = glfw.glfwGetRequiredInstanceExtensions(&count);
    const array = try allocator.alloc([*c]const u8, count + 1);
    for (0..count) |i| {
        array[i] = extensions[i];
    }

    array[count] = vulkan.VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME;
    return Extensions{
        .count = count,
        .extensions = array,
    };
}

const Window = struct {
    ptr: WindowPtr,
    const Self = @This();
    pub fn should_close(self: *const Self) bool {
        return glfw.glfwWindowShouldClose(self.ptr) == glfw.GLFW_TRUE;
    }

    pub fn destroy(self: *const Self) void {
        glfw.glfwDestroyWindow(self.ptr);
    }
};
