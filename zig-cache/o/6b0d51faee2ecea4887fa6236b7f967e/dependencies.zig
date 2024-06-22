pub const packages = struct {
    pub const @"122067b39a4f454ece4e800ee95e0002a767b535d647c6042ac93bc195100683ba03" = struct {
        pub const build_root = "/Users/frde/.cache/zig/p/122067b39a4f454ece4e800ee95e0002a767b535d647c6042ac93bc195100683ba03";
        pub const build_zig = @import("122067b39a4f454ece4e800ee95e0002a767b535d647c6042ac93bc195100683ba03");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10" = struct {
        pub const build_root = "/Users/frde/.cache/zig/p/1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "vulkan_zig", "122067b39a4f454ece4e800ee95e0002a767b535d647c6042ac93bc195100683ba03" },
    .{ "vulkan_headers", "1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10" },
};
