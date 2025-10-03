
const std = @import("std");
const mmio = @import("mmio.zig");


regs: *volatile mmio.SPI,

pub fn spi_stream(self: @This(), tx_data: []const u8, rx_data: []u8) void {

	std.debug.assert(tx_data.len == rx_data.len);

	var write_buf = tx_data;
	var read_buf = rx_data;

	// flush read buffer
	while (self.regs.status.receive_ready) std.mem.doNotOptimizeAway(self.regs.data.bits_8);

	while (read_buf.len > 0) {
		while (self.regs.status.transmit_ready and write_buf.len > 0) {
			self.regs.data.bits_8 = write_buf[0];
			write_buf = write_buf[1..];
		}

		while (self.regs.status.receive_ready and read_buf.len > 0) {
			read_buf[0] = self.regs.data.bits_8;
			read_buf = read_buf[1..];
		}
	}
}

pub fn spi_write(self: @This(), data: []const u8) void {

	var buffer = data;

	while (buffer.len > 0) {
		while (self.regs.status.transmit_ready and buffer.len > 0) {
			self.regs.data.bits_8 = buffer[0];
			buffer = buffer[1..];
		}

		while (self.regs.status.receive_ready) std.mem.doNotOptimizeAway(self.regs.data.bits_8);
	}
}

pub fn spi_read(self: @This(), data: []u8) void {

	var write_counter = data.len;
	var buffer = data;

	// flush read buffer
	while (self.regs.status.receive_ready) std.mem.doNotOptimizeAway(self.regs.data.bits_8);

	while (buffer.len > 0) {
		while (self.regs.status.transmit_ready and write_counter > 0) {
			self.regs.data.bits_8 = 0;
			write_counter -= 1;
		}

		while (self.regs.status.receive_ready and buffer.len > 0) {
			buffer[0] = self.regs.data.bits_8;
			buffer = buffer[1..];
		}
	}
}
