const std = @import("std");




fn flash_step(b: *std.Build, fw_name: []const u8) !*std.Build.Step.Run {
	const openocd_command = try std.fmt.allocPrint(b.allocator, "program {s} verify reset exit", .{
		b.getInstallPath(.bin, fw_name),
	});

	defer b.allocator.free(openocd_command);

	const flash = b.addSystemCommand(&.{
		"openocd",
		"-f", "interface/stlink.cfg",
		"-f", "target/stm32l4x.cfg",
		"-c", openocd_command,
	});

	return flash;
}

pub fn build(b: *std.Build) void {

	const host_target = b.standardTargetOptions(.{});
	const device_target = b.resolveTargetQuery(.{
		.cpu_arch = .thumb,
		.cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
		.os_tag = .freestanding,
		.cpu_features_add = std.Target.arm.featureSet(&.{.vfp4d16sp}),
		.abi = .eabi,
	});
	_ = host_target;


	const optimize = b.standardOptimizeOption(.{});
	_ = optimize;

	const fw = b.addExecutable(.{
		.name = "embedded.elf",
		.root_module = b.createModule(.{
			.root_source_file = b.path("src/main.zig"),
			.target = device_target,
			.optimize = .ReleaseSmall,
			.imports = &.{
			},
		}),
	});
	fw.linker_script = b.path("linker.ld");

	b.installArtifact(fw);


	if (flash_step(b, fw.name) catch null) |flash| {
		flash.step.dependOn(b.getInstallStep());
		b.step("flash", "Build + Flash with openocd").dependOn(&flash.step);
	}

}
