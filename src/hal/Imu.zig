
const std = @import("std");
const Spi = @import("Spi.zig");
const gpio = @import("gpio.zig");


spi: Spi,

cs_pin: gpio.Pin,

pub const RegAddr = u7;


const RW = enum(u1) {
	Read  = 1,
	Write = 0,
};

const Header = packed struct(u8) {
	addr: RegAddr,
	rw: RW,
};


pub fn config_spi(self: @This()) void {
	self.spi.regs.config.enable = false;

	self.spi.regs.config.role = .master;
	self.spi.regs.config.baudrate = .div_16;
	self.spi.regs.config.bit_order = .msb_first;

	self.spi.regs.config._SSM = 1;
	self.spi.regs.config._SSI = 1;

	self.spi.regs.config.min_receive_amount = .bits_8; // Important!

	self.spi.regs.config.data_size = .bits_8;

	self.spi.regs.config.directions = .duplex;

	self.spi.regs.config.enable = true;
}



pub fn set_reg(self: @This(), reg: RegAddr, value: u8) void {
	std.log.info("at set", .{});

	const cmd = [2]u8{
		@bitCast(Header{
		.addr = reg,
		.rw = .Write,
	}), value };

	self.cs_pin.set_output(false);
	self.spi_write(&cmd);
	self.cs_pin.set_output(true);
}

pub fn get_reg(self: @This(), reg: RegAddr) u8 {
	var buf = [2]u8{@bitCast(Header{
		.addr = reg,
		.rw = .Read,
	}), 0x00 };

	self.cs_pin.set_output(false);
	self.spi.spi_stream(&buf, &buf);
	self.cs_pin.set_output(true);

	return buf[1];
}


