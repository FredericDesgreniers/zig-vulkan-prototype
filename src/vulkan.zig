const vulkan = @cImport({
    @cInclude("vulkan/vulkan.h");
});

const std = @import("std");

const glfw = @import("glfw.zig");

const builtin = @import("builtin");
const isDebugMode = builtin.mode == .Debug;

const EXPECTED_VALIDATION_LAYERS = [_][]const u8{
    "VK_LAYER_KHRONOS_validation",
};

pub fn supportsValidationLayers(allocator: std.mem.Allocator) !bool {
    var layer_count: u32 = undefined;
    _ = vulkan.vkEnumerateInstanceLayerProperties(&layer_count, null);

    const availableLayers = try allocator.alloc(vulkan.VkLayerProperties, layer_count);
    defer allocator.free(availableLayers);
    _ = vulkan.vkEnumerateInstanceLayerProperties(&layer_count, availableLayers.ptr);

    for (EXPECTED_VALIDATION_LAYERS) |expectedLayer| {
        var found = false;
        for (availableLayers) |layer| {
            if (std.mem.startsWith(u8, &layer.layerName, expectedLayer)) {
                found = true;
                break;
            }
        }
        if (!found) {
            return false;
        }
    }

    return true;
}

const QueueFamilies = struct { graphics_family: ?u32 };

const LogicalDevice = struct {
    device: vulkan.VkDevice,
    const Self = @This();

    pub fn get_device_queue(self: *const Self) !vulkan.VkQueue {
        var queue: vulkan.VkQueue = undefined;
        vulkan.vkGetDeviceQueue(self.device, 0, 0, &queue);
        return queue;
    }

    pub fn destroy(self: *const Self) void {
        vulkan.vkDestroyDevice(self.device, null);
    }
};

const PhysicalDevice = struct {
    device: vulkan.VkPhysicalDevice,
    const Self = @This();

    fn is_device_suitable(self: *const Self, allocator: std.mem.Allocator) !bool {
        const queues = try self.find_queue_families(allocator);
        if (queues.graphics_family == null) {
            std.debug.print("Failed to find a queue family\n", .{});
            return false;
        }

        var properties: vulkan.VkPhysicalDeviceProperties = undefined;
        vulkan.vkGetPhysicalDeviceProperties(self.device, &properties);
        var features: vulkan.VkPhysicalDeviceFeatures = undefined;
        vulkan.vkGetPhysicalDeviceFeatures(self.device, &features);
        const ENABLE_GEOMETRY_SHADER_REQUIREMENT = false;
        const shader_requirements = ((features.geometryShader == vulkan.VK_TRUE) or !ENABLE_GEOMETRY_SHADER_REQUIREMENT);
        std.debug.print("Device name: {s}, device_type: {} (needs {}), geometry shaders: {}, shader_requirements: {}\n", .{ properties.deviceName, properties.deviceType, vulkan.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU, features.geometryShader, shader_requirements });
        const supported_device_types = [_]vulkan.VkPhysicalDeviceType{
            vulkan.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU,
            vulkan.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU,
            vulkan.VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU,
        };
        var is_supported_device_type = false;
        for (supported_device_types) |supported_device_type| {
            if (properties.deviceType == supported_device_type) {
                is_supported_device_type = true;
                break;
            }
        }
        const suitable = is_supported_device_type and shader_requirements;
        std.debug.print("Device is suitable: {}\n", .{suitable});
        return suitable;
    }

    pub fn find_queue_families(self: *const Self, allocator: std.mem.Allocator) !QueueFamilies {
        var queue_family_count: u32 = 0;
        vulkan.vkGetPhysicalDeviceQueueFamilyProperties(self.device, &queue_family_count, null);
        var queue_families = try allocator.alloc(vulkan.VkQueueFamilyProperties, queue_family_count);
        vulkan.vkGetPhysicalDeviceQueueFamilyProperties(self.device, &queue_family_count, &queue_families[0]);
        var graphics_family: ?u32 = null;
        for (0.., queue_families) |i, queue_family| {
            if ((queue_family.queueFlags & vulkan.VK_QUEUE_GRAPHICS_BIT) > 0) {
                graphics_family = @intCast(i);
                break;
            }
        }
        return QueueFamilies{ .graphics_family = graphics_family };
    }

    pub fn create_logical_device(self: *const Self, allocator: std.mem.Allocator) !LogicalDevice {
        const queue_families = try self.find_queue_families(allocator);
        const queue_priorities = [_]f32{1.0};
        const info = vulkan.VkDeviceQueueCreateInfo{
            .sType = vulkan.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = queue_families.graphics_family.?,
            .queueCount = 1,
            .pQueuePriorities = &queue_priorities,
        };

        const device_features = vulkan.VkPhysicalDeviceFeatures{};

        var create_info = vulkan.VkDeviceCreateInfo{
            .sType = vulkan.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = 1,
            .pQueueCreateInfos = &info,
            .pEnabledFeatures = &device_features,
            .enabledExtensionCount = 0,
        };

        if (isDebugMode) {
            create_info.enabledLayerCount = EXPECTED_VALIDATION_LAYERS.len;
            create_info.ppEnabledLayerNames = @ptrCast(&EXPECTED_VALIDATION_LAYERS);
        } else {
            create_info.enabledLayerCount = 0;
        }

        var device: vulkan.VkDevice = undefined;

        if (vulkan.vkCreateDevice(self.device, &create_info, null, &device) == vulkan.VK_SUCCESS) {
            return LogicalDevice{ .device = device };
        } else {
            return Errors.CreateDeviceError;
        }
    }
};

const VulkanInstance = struct {
    instance: vulkan.VkInstance,
    const Self = @This();
    pub fn destroy(self: *const Self) void {
        vulkan.vkDestroyInstance(self.instance, null);
    }

    pub fn pick_physical_device(self: *const Self, allocator: std.mem.Allocator) !?PhysicalDevice {
        var device_count: u32 = undefined;
        _ = vulkan.vkEnumeratePhysicalDevices(self.instance, &device_count, null);

        if (device_count == 0) {
            std.debug.print("Failed to find GPUs with Vulkan support\n", .{});
            return null;
        }

        const devices = try allocator.alloc(vulkan.VkPhysicalDevice, device_count);
        defer allocator.free(devices);

        _ = vulkan.vkEnumeratePhysicalDevices(self.instance, &device_count, devices.ptr);

        var physical_device: ?PhysicalDevice = null;

        std.debug.print("Found {d} GPUs\n", .{device_count});
        for (devices) |physical_device_candidate| {
            const device = PhysicalDevice{ .device = physical_device_candidate };
            std.debug.print("Considering a GPU\n", .{});
            if (try device.is_device_suitable(allocator)) {
                std.debug.print("Found a suitable GPU\n", .{});
                physical_device = device;
                break;
            }
        }

        if (physical_device == null) {
            std.debug.print("Failed to find a suitable GPU\n", .{});
            return null;
        }

        return physical_device;
    }
};

const Errors = error{
    ValidationLayersNotSupported,
    CreateDeviceError,
};

pub fn create_instance(allocator: std.mem.Allocator) !?VulkanInstance {
    if (isDebugMode and !try supportsValidationLayers(allocator)) {
        return Errors.ValidationLayersNotSupported;
    }

    const app_info = vulkan.VkApplicationInfo{
        .sType = vulkan.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "Hello Triangle",
        .applicationVersion = vulkan.VK_MAKE_VERSION(1, 0, 0),
        .pEngineName = "No Engine",
        .engineVersion = vulkan.VK_MAKE_VERSION(1, 0, 0),
        .apiVersion = vulkan.VK_API_VERSION_1_0,
    };

    const extensions = try glfw.getExtensions(allocator);

    const creation_info = vulkan.VkInstanceCreateInfo{
        .sType = vulkan.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledExtensionCount = @intCast(extensions.extensions.len),
        .ppEnabledExtensionNames = extensions.extensions.ptr,
        .enabledLayerCount = 0,
        .flags = vulkan.VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
    };

    var instance: vulkan.VkInstance = undefined;
    const result = vulkan.vkCreateInstance(&creation_info, null, &instance);
    if (result != vulkan.VK_SUCCESS) {
        std.debug.print("Failed to create Vulkan instance {}\n", .{result});
        return undefined;
    }

    return VulkanInstance{ .instance = instance };
}
