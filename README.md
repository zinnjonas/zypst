# zypst
A zig module to ease the communication with typst. 

## Example

This is an example `build.zig` to use the module with the example file inside this directory.

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const zypst = b.addModule("zypst", .{ .root_source_file = b.path("zypst.zig") });

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const extension = b.addExecutable(.{
        .name = "zypst-example",
        .root_source_file = b.path("example.zig"),
        .strip = true,
        .target = target,
        .optimize = .ReleaseSmall,
    });

    extension.entry = .disabled;
    extension.rdynamic = true;

    extension.root_module.addImport("zypst", zypst);

    b.installArtifact(extension);
}

```
