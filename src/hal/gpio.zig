

const std = @import("std");
const mmio = @import("mmio.zig");


pub const Pin = struct {
	root_controller: *volatile mmio.GPIO_Regs,
	pin_num: u4,

	pub fn set_mode(self: @This(), mode: mmio.GpioMode) void {
		const shift = @as(u5, self.pin_num)*2;
		const base: u32 = @as(u2, @bitCast(mode));

		const shifted = base << shift;
		const mask = ~(@as(u32, 0b11) << shift);

		const ptr: *volatile u32 = @ptrCast(&self.root_controller.mode);

		ptr.* = (ptr.* & mask) | shifted;
	}

	pub fn set_output(self: @This(), value: bool) void {
		const base: u16 = if (value) 1 else 0;

		const shifted = base << self.pin_num;
		const mask = ~(@as(u16, 0b1) << self.pin_num);

		const ptr: *volatile u16 = @ptrCast(&self.root_controller.output);

		ptr.* = (ptr.* & mask) | shifted;
	}

	pub fn set_alt_func(self: @This(), func: u4) void {
		const shift = @as(u6, self.pin_num)*4;
		const base: u64 = func;

		const shifted = base << shift;
		const mask = ~(@as(u64, 0b1111) << shift);

		const ptr: *volatile u32 = @ptrCast(&self.root_controller.alt_func);

		ptr.* = (ptr.* & mask) | shifted;
	}
};





