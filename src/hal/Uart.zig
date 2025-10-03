const std = @import("std");
const mmio = @import("mmio.zig");

const Writer = std.Io.Writer;
const Reader = std.Io.Reader;

pub const Config = struct {
	echo: bool = true,
};

regs: *volatile mmio.USART,
writer: Writer,
reader: Reader,

config: Config,

pub fn init(uart_regs: *volatile mmio.USART, writer_buffer: []u8, reader_buffer: []u8, config: Config) @This() {
	return .{
		.regs = uart_regs,
		.writer = .{
			.vtable = &.{
				.drain = drain,
			},
			.buffer = writer_buffer,
		},
		.reader = .{
			.vtable = &.{
				.stream = stream,
			},
			.buffer = reader_buffer,
			.seek = 0,
			.end = 0,
		},
		.config = config,
	};
}

fn stream(r: *Reader, w: *Writer, limit: std.Io.Limit) Reader.StreamError!usize {
	switch (limit) {
		// Why would this even ever be passed?
		.nothing => return 0,
		else => {},
	}

	const self: *@This() = @fieldParentPtr("reader", r);

	if (self.regs.status.receive_ready) {
		const c: u8 = @truncate(self.regs.receive_data);
		try w.writeByte(c);

		if (self.config.echo) {
			self.write_byte(c);

			// TODO: Find a more elegant solution
			if (c == '\n') self.write_byte('\r');
			if (c == '\r') self.write_byte('\n');
		}
		return 1;
	} else {
		return 0;
	}
}

pub fn write_byte(self: @This(), b: u8) void {
	// Wait until TXE (Transmit data register empty) flag is set
	while (!self.regs.status.transmit_ready) {}
	self.regs.transmit_data = b;
}

pub fn write_str(self: @This(), s: []const u8) void {
	for (s) |c| self.write_byte(c);
}

fn drain(w: *Writer, data: []const []const u8, splat: usize) Writer.Error!usize {
	const self: *@This() = @fieldParentPtr("writer", w);

	var count: usize = 0;

	// consume buffer
	self.write_str(w.buffer[0..w.end]);
	w.end = 0;

	const tail = data.len - 1;
	for (data[0..tail]) |str| {
		self.write_str(str);
		count += str.len;
	}

	for (0..splat) |_| self.write_str(data[tail]);
	count += splat * data[tail].len;

	return count;
}
