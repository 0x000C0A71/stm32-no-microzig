
const std = @import("std");
const mmio = @import("mmio.zig");

spi: *volatile mmio.SPI,

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
	self.spi.config.enable = false;

	self.spi.config.role = .master;
	self.spi.config.baudrate = .div_16;
	self.spi.config.bit_order = .msb_first;

	self.spi.config._SSM = 1;
	self.spi.config._SSI = 1;

	self.spi.config.data_size = .bits_8;
	
	self.spi.config.enable = true;
}


inline fn spi_stream(self: @This(), data: u8) u8 {
	while (!self.spi.status.transmit_ready) {}
	self.spi.data.bits_8 = data;

	while (!self.spi.status.receive_ready) {}
	return self.spi.data.bits_8;
}

inline fn spi_write(self: @This(), data: u8) void {
	std.mem.doNotOptimizeAway(self.spi_stream(data));
}

inline fn spi_read(self: @This()) u8 {
	return self.spi_stream(0);
}


pub fn set_reg(self: @This(), reg: RegAddr, value: u8) void {
	self.spi_write(@bitCast(Header{
		.addr = reg,
		.rw = .Write,
	}));

	self.spi_write(value);
}

pub fn get_reg(self: @This(), reg: RegAddr) u8 {
	self.spi_write(@bitCast(Header{
		.addr = reg,
		.rw = .Write,
	}));

	return self.spi_read();
}


