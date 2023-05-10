const std = @import("std");
const http = std.http;

pub fn build(b: *std.Build) !void {
    // var client = http.Client{ .allocator = b.allocator };
    // defer client.deinit();
    // var headers = http.Headers.init(b.allocator);
    // defer headers.deinit();
    // const uri = try std.Uri.parse("https://github.com/jart/cosmopolitan/releases/download/0.2/cosmopolitan-amalgamation-0.2.zip");
    // var request = try client.request(
    //     .GET,
    //     uri,
    //     headers,
    //     .{},
    // );
    // defer request.deinit();
    // var reader = request.reader();

    // std.debug.print("data len {d}\n", .{data.len});
    const final_step = b.step("ape", "Create ape bin");

    b.default_step = final_step;

    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .musl,
    } });

    const optimize = .ReleaseSmall;

    const th = b.addTranslateC(.{
        .source_file = .{ .path = "cosmopolitan/cosmopolitan.h" },
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addObject(.{
        .name = "zig-code",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .link_libc = false,
        .optimize = optimize,
    });

    const cosmopolitan_zig = b.addModule("cosmopolitan", .{
        .source_file = .{ .generated = &th.output_file },
    });

    lib.linkage = .static;

    lib.addModule("cosmopolitan", cosmopolitan_zig);

    lib.strip = true;

    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "cosmo-zig",
        .link_libc = false,
        .optimize = optimize,
        .target = target,
        .linkage = .static,
    });

    exe.addObject(lib);

    exe.addObjectFile("cosmopolitan/crt.o");
    exe.addObjectFile("cosmopolitan/ape.o");
    exe.addObjectFile("cosmopolitan/cosmopolitan.a");
    // exe.addObjectFile("cosmopolitan/cosmopolitan.h");

    // exe.emit_bin = .{.emit_to }
    exe.dwarf_format = .@"64";

    exe.strip = true;

    exe.link_z_max_page_size = 0x1000;

    exe.link_gc_sections = true;

    exe.pie = false;

    exe.red_zone = false;

    exe.setVerboseCC(true);
    exe.omit_frame_pointer = false;

    exe.linker_script = .{ .path = "cosmopolitan/ape.lds" };

    const create_ape = exe.addObjCopy(.{
        .basename = "cosmo-zig.com",
        .format = .bin,
    });

    final_step.dependOn(&create_ape.step);

    b.installArtifact(exe);
}
