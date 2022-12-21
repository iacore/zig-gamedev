const std = @import("std");

pub const Backend = enum {
    no_backend,
    glfw_wgpu,
    win32_d3d12,
};

pub const BuildOptions = struct {
    backend: Backend,
};

pub const BuildOptionsStep = struct {
    options: BuildOptions,
    step: *std.build.OptionsStep,

    pub fn init(b: *std.build.Builder, options: BuildOptions) BuildOptionsStep {
        const bos = .{
            .options = options,
            .step = b.addOptions(),
        };
        bos.step.addOption(Backend, "backend", bos.options.backend);
        return bos;
    }

    pub fn getPkg(bos: BuildOptionsStep) std.build.Pkg {
        return bos.step.getPackage("zgui_options");
    }

    fn addTo(bos: BuildOptionsStep, target_step: *std.build.LibExeObjStep) void {
        target_step.addOptions("zgui_options", bos.step);
    }
};

pub fn getPkg(dependencies: []const std.build.Pkg) std.build.Pkg {
    return .{
        .name = "zgui",
        .source = .{ .path = thisDir() ++ "/src/main.zig" },
        .dependencies = dependencies,
    };
}

pub fn link(exe: *std.build.LibExeObjStep, bos: BuildOptionsStep) void {
    bos.addTo(exe);

    exe.addIncludePath(thisDir() ++ "/libs");

    exe.linkSystemLibraryName("c");
    exe.linkSystemLibraryName("c++");

    const cflags = &.{"-fno-sanitize=undefined"};

    exe.addCSourceFile(thisDir() ++ "/src/zgui.cpp", cflags);

    exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_widgets.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_tables.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_draw.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_demo.cpp", cflags);

    exe.addCSourceFile(thisDir() ++ "/libs/imgui/implot_demo.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/implot.cpp", cflags);
    exe.addCSourceFile(thisDir() ++ "/libs/imgui/implot_items.cpp", cflags);

    switch (bos.options.backend) {
        .glfw_wgpu => {
            exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_impl_glfw.cpp", cflags);
            exe.addCSourceFile(thisDir() ++ "/libs/imgui/imgui_impl_wgpu.cpp", cflags);
        },
        .win32_d3d12 => {},
        .no_backend => {},
    }
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
