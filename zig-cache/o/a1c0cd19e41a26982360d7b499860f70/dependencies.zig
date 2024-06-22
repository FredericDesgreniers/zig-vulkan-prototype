pub const packages = struct {
    pub const @"1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10" = struct {
        pub const build_root = "/Users/frde/.cache/zig/p/1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220d51ef5c80e63c8af8394d7a6562c12045847b6676da941e3fd00315242cbff11" = struct {
        pub const build_root = "/Users/frde/.cache/zig/p/1220d51ef5c80e63c8af8394d7a6562c12045847b6676da941e3fd00315242cbff11";
        pub const build_zig = @import("1220d51ef5c80e63c8af8394d7a6562c12045847b6676da941e3fd00315242cbff11");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "vulkan_zig", "1220d51ef5c80e63c8af8394d7a6562c12045847b6676da941e3fd00315242cbff11" },
    .{ "vulkan_headers", "1220a7e73d72a0d56bc2a65f9d8999a7c019e42260a0744c408d1cded111bc205e10" },
};
