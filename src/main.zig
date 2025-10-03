const std = @import("std");


const hal = @import("hal.zig");


fn get_heap() []u8 {
	const sheap: [*]u8 = @extern([*]u8, .{ .name = "_sheap" });
	const eheap: [*]u8 = @extern([*]u8, .{ .name = "_eheap" });

	const heap_size = @intFromPtr(eheap) - @intFromPtr(sheap);

	return sheap[0..heap_size];
}


// Use with caution!
// Freeing a resource only frees it if it was the most recently allocated
// resource. Otherwise, it will just be leaked (!!!), which is quite
// devestating on an embedded system.
//var _heap_bump_allocator = std.heap.FixedBufferAllocator.init(heap);

const umm = @import("umm.zig");



// The function called when the MCU resets
export fn _start() callconv(.c) noreturn {
	
	// Zero-initialize the BSS section in ram
	const sbss: [*]u8 = @extern([*]u8, .{ .name = "_sbss" });
	const ebss: [*]u8 = @extern([*]u8, .{ .name = "_ebss" });

	const bss_size = @intFromPtr(ebss) - @intFromPtr(sbss);

	@memset(sbss[0..bss_size], 0);

	// Copy the data from the data section to ram
	const edata: [*]u8 = @extern([*]u8, .{ .name = "_edata" });
	const sdata: [*]u8 = @extern([*]u8, .{ .name = "_sdata" });
	const mdata: [*]u8 = @extern([*]u8, .{ .name = "_mdata" });

	const data_size = @intFromPtr(edata) - @intFromPtr(sdata);

	@memcpy(mdata[0..data_size], sdata[0..data_size]);

	// Call main. If error handling is requested. this is where to do it
	@call(.never_inline, main, .{}) catch unreachable;

	// Spin once the main function has returned. Optimally this would never
	// happen. It might be a good idea to jump back up to the start of the
	// function if this happens
	while (true) {}
}


// Setting the necessary values in the vtable
export const vtable linksection(".isr_vector") = hal.mmio.VectorTable{
	.initial_stack_pointer = @extern(*anyopaque, .{ .name = "_estack" }),
	.Reset = .{ .c = &_start },
};


// Setting up pointers to hardware registers
const PERIPH_BASE: usize = 0x40000000;

const AHB2PERIPH_BASE     = (PERIPH_BASE + 0x08000000);
const APB1PERIPH_BASE     = (PERIPH_BASE + 0x00000000);

const GPIOA_BASE          = (AHB2PERIPH_BASE + 0x000);
const GPIOB_BASE          = (AHB2PERIPH_BASE + 0x400);
const GPIOC_BASE          = (AHB2PERIPH_BASE + 0x800);

const RCC_BASE            = (0x40021000);
const SPI2_BASE           = (APB1PERIPH_BASE + 0x3800);
const USART2_BASE         = (APB1PERIPH_BASE + 0x4400);

const RCC:          *volatile hal.mmio.RCC       = @ptrFromInt(RCC_BASE);
const GPIO_A:       *volatile hal.mmio.GPIO_Regs = @ptrFromInt(GPIOA_BASE     );
const GPIO_B:       *volatile hal.mmio.GPIO_Regs = @ptrFromInt(GPIOB_BASE     );
const GPIO_C:       *volatile hal.mmio.GPIO_Regs = @ptrFromInt(GPIOC_BASE     );
const USART_2:      *volatile hal.mmio.USART     = @ptrFromInt(USART2_BASE    );
const SPI_2:        *volatile hal.mmio.SPI       = @ptrFromInt(SPI2_BASE);

fn spi_setup(spi: *volatile hal.mmio.SPI) void {
	spi.config.enable = false;

	spi.config.role = .master;
	spi.config.baudrate = .div_16;
	spi.config.bit_order = .msb_first;

	spi.config._SSM = 1;
	spi.config._SSI = 1;

	spi.config.data_size = .bits_8;
	
	spi.config.enable = true;
}




// A crude delay function
fn delay() void {
	var i: u32 = 0;
	while (i < 800_00) : (i += 1) {
		asm volatile ("nop");
	}
}


fn uart2_init() void {
	// Enable GPIOA and USART2 clocks
	RCC.AHB2ENR.GPIOAEN = true;
	RCC.APB1ENR1.uart_2_enable = true;

	GPIO_A.mode.pin_0x2 = .alt_func;
	GPIO_A.mode.pin_0x3 = .alt_func;

	GPIO_A.alt_func.pin_0x2 = 7;
	GPIO_A.alt_func.pin_0x3 = 7;


	// USART2: baud rate register
	const fck = 4_000_000; // default MSI
	const baud = 9600;
	const brr_val: u16 = fck / baud;

	USART_2.baudrate_div = brr_val;

	// Enable UE, TE, RE
	USART_2.control.enable = true;
	USART_2.control.transmitter_enable = true;
	USART_2.control.receiver_enable = true;
}



// For logging
pub const std_options: std.Options = .{
	// Set the log level to info
	.log_level = .info,

	// Define logFn to override the std implementation
	.logFn = uart_log_fn,
};

var writer_for_logging: ?*std.Io.Writer = null;

pub fn uart_log_fn(
	comptime level: std.log.Level,
	comptime scope: @Type(.enum_literal),
	comptime format: []const u8,
	args: anytype,
) void {
	const prefix = "[ " ++ comptime level.asText() ++ " ] <" ++ @tagName(scope) ++ ">: ";
	if (writer_for_logging) |w| {
		w.print(prefix ++ format ++ "\n\r", args) catch unreachable;
		w.flush() catch unreachable;
	}
}


fn spi_test() void {

	RCC.AHB2ENR.GPIOAEN = true;
	RCC.AHB2ENR.GPIOBEN = true;
	RCC.AHB2ENR.GPIOCEN = true;
	RCC.APB1ENR1.spi2_enable = true;

	GPIO_C.mode.pin_0x3 = .alt_func; // mosi pin
	GPIO_B.mode.pin_0xD = .alt_func; // sclk pin
	GPIO_B.mode.pin_0xB = .output; // latch pin

	GPIO_C.alt_func.pin_0x3 = 5;
	GPIO_B.alt_func.pin_0xD = 5;

	
	spi_setup(SPI_2);

	while (!SPI_2.status.transmit_ready) {}
	SPI_2.data.bits_8 = 0xff;
	while (!SPI_2.status.transmit_ready) {}
	SPI_2.data.bits_8 = 0xff;
	while (!SPI_2.status.transmit_ready) {}
	SPI_2.data.bits_8 = 0xff;

	while (!SPI_2.status.transmit_ready) {}
	//std.mem.doNotOptimizeAway(SPI_2.data);
	//std.mem.doNotOptimizeAway(SPI_2.status);

	delay();
	GPIO_B.output.pin_0xB = true;
	GPIO_B.output.pin_0xB = false;
}



const led_matrix = struct {
	pub const Color = enum {
		Black, Green, Red, Yellow,
	};
	pub const Frame = struct {
		pixels: [3][4]Color,

		pub fn pack(self: @This()) [3]u8 {
			var red_plane:   u12 = 0;
			var green_plane: u12 = 0;

			for (self.pixels, 0..) |line, y| {
				for (line, 0..) |pixel, x| {
					const index = y*4+x;

					const mask = @as(u12, 1) << @intCast(index);

					switch (pixel) {
						.Red    => red_plane   |= mask,
						.Green  => green_plane |= mask,
						.Yellow => {
							green_plane |= mask;
							red_plane   |= mask;
						},
						.Black => {},
					}
				}
			}

			const pcked: u24 = @as(u24, red_plane) << 12 | green_plane;
			return @bitCast(pcked);
		}
	};


	pub fn setup() void {
		RCC.AHB2ENR.GPIOAEN = true;
		RCC.AHB2ENR.GPIOBEN = true;
		RCC.AHB2ENR.GPIOCEN = true;
		RCC.APB1ENR1.spi2_enable = true;

		GPIO_C.mode.pin_0x3 = .alt_func; // mosi pin
		GPIO_B.mode.pin_0xD = .alt_func; // sclk pin
		GPIO_B.mode.pin_0xB = .output; // latch pin

		GPIO_C.alt_func.pin_0x3 = 5;
		GPIO_B.alt_func.pin_0xD = 5;

		spi_setup(SPI_2);
	}

	pub fn push_frame(frame: Frame) void {
		const parts = frame.pack();

		GPIO_B.output.pin_0xB = false;

		while (!SPI_2.status.transmit_ready) {}
		SPI_2.data.bits_8 = parts[2];
		while (!SPI_2.status.transmit_ready) {}
		SPI_2.data.bits_8 = parts[1];
		while (!SPI_2.status.transmit_ready) {}
		SPI_2.data.bits_8 = parts[0];
		while (!SPI_2.status.transmit_ready) {}

		asm volatile (
			\\nop
			\\nop
			\\nop
		);

		GPIO_B.output.pin_0xB = true;
		GPIO_B.output.pin_0xB = false;
	}

};

// For the parser example
const Parser = @import("Parser.zig");

fn main() !void {
	RCC.AHB2ENR.GPIOAEN = true;
	GPIO_A.mode.pin_0x5 = .output;

	const heap = get_heap();

	var umm_alloc = try umm.UmmAllocator(.{}).init(heap);
	defer _ = umm_alloc.deinit();

	const alloc = umm_alloc.allocator();

	uart2_init();

	var wbuff: [16]u8 = undefined;
	var rbuff: [16]u8 = undefined;

	var uart2 = hal.Uart.init(USART_2, &wbuff, &rbuff, .{});

	// Set as logger
	writer_for_logging = &uart2.writer;
	defer writer_for_logging = null;

	{
		const sbss:  [*]u8 = @extern([*]u8, .{ .name = "_sbss"   });
		const ebss:  [*]u8 = @extern([*]u8, .{ .name = "_ebss"   });

		const edata: [*]u8 = @extern([*]u8, .{ .name = "_edata"  });
		const sdata: [*]u8 = @extern([*]u8, .{ .name = "_sdata"  });
		const mdata: [*]u8 = @extern([*]u8, .{ .name = "_mdata"  });

		const sheap: [*]u8 = @extern([*]u8, .{ .name = "_sheap"  });
		const eheap: [*]u8 = @extern([*]u8, .{ .name = "_eheap"  });

		const stack: [*]u8 = @extern([*]u8, .{ .name = "_estack" });


		std.log.info("--- symbols are  ---", .{});
		std.log.info(" - sbss:  0x{x:0>8}", .{ @intFromPtr(sbss ) });
		std.log.info(" - ebss:  0x{x:0>8}", .{ @intFromPtr(ebss ) });
		std.log.info(" - edata: 0x{x:0>8}", .{ @intFromPtr(edata) });
		std.log.info(" - sdata: 0x{x:0>8}", .{ @intFromPtr(sdata) });
		std.log.info(" - mdata: 0x{x:0>8}", .{ @intFromPtr(mdata) });
		std.log.info(" - sheap: 0x{x:0>8}", .{ @intFromPtr(sheap) });
		std.log.info(" - eheap: 0x{x:0>8}", .{ @intFromPtr(eheap) });
		std.log.info(" - stack: 0x{x:0>8}", .{ @intFromPtr(stack) });
		std.log.info("--- symbols over ---", .{});
	}

	try uart2.writer.print("Moin!\n\r", .{});
	try uart2.writer.flush();

	// SPI
	//@call( .never_inline, spi_test, .{});



	switch (5) {
		0 => { // LED blink
			var counter: usize = 0;

			while (true) {
				// Turn LED on (set PA5)
				GPIO_A.output.pin_0x5 = true;
				delay();
				delay();

				// Turn LED off (clear PA5)
				GPIO_A.output.pin_0x5 = false;
				delay();
				delay();

				try uart2.writer.print("Counter: {}\n\r", .{counter});
				try uart2.writer.flush();

				counter += 1;
			}
		},
		1 => { // expr evaluater
			var parser = Parser{ .reader = &uart2.reader };

			try uart2.writer.print("Try something like `10*(2 + 4)%15`!\n\r", .{});
			try uart2.writer.flush();

			while (true) {
				const val = parser.parse() catch |err| {
					switch (err) {
						error.IllegalToken,
						error.IllegalCharacter,
						error.MissingClosingParen,
						=> |e| {
							try uart2.writer.print("\n\rFail! {}\n\r", .{e});
							try uart2.writer.flush();
						},
						else => |e| return e,
					}
					continue;
				};

				try uart2.writer.print("got {}\n\r", .{val});
				try uart2.writer.flush();
			}
		},
		2 => {
			GPIO_B.output.pin_0xB = false;

			var counter: usize = 0;
			while (true) {
				for (0..4) |_| delay();

				const col: u8 = if (@mod(counter, 12) < 6) 0x00 else 0xff;

				while (!SPI_2.status.transmit_ready) {}
				SPI_2.data.bits_8 = col;
				while (!SPI_2.status.transmit_ready) {}

				delay();
				GPIO_B.output.pin_0xB = true;
				GPIO_B.output.pin_0xB = false;

				std.log.info("sent 0x{x}", .{col});
				counter += 1;
			}
		},
		3 => {
			led_matrix.setup();

			var counter: usize = 0;
			var bits: [3]u4 = undefined;

			while (true) {


				if (USART_2.status.receive_ready) {
					// get data
					const c = USART_2.receive_data;

					bits = switch (c) {
						'a', 'A' => .{
							0b1110,
							0b0101,
							0b1110,
						},
						'b', 'B' => .{
							0b1111,
							0b1010,
							0b1110,
						},
						'c', 'C' => .{
							0b1110,
							0b1010,
							0b1010,
						},
						'd', 'D' => .{
							0b1110,
							0b1010,
							0b1111,
						},
						'e', 'E' => .{
							0b1111,
							0b1101,
							0b1001,
						},
						'f', 'F' => .{
							0b1111,
							0b0101,
							0b0001,
						},
						'g', 'G' => .{
							0b1110,
							0b1001,
							0b1101,
						},
						'h', 'H' => .{
							0b1111,
							0b0010,
							0b1110,
						},
						'i', 'I' => .{
							0b1001,
							0b1111,
							0b1001,
						},
						'j', 'J' => .{
							0b0101,
							0b1001,
							0b0111,
						},
						'k', 'K' => .{
							0b1111,
							0b0100,
							0b1010,
						},
						'l', 'L' => .{
							0b1111,
							0b1000,
							0b1000,
						},
						'm', 'M' => .{
							0b1111,
							0b1110,
							0b1111,
						},
						'n', 'N' => .{
							0b1011,
							0b0110,
							0b1101,
						},
						'o', 'O' => .{
							0b1110,
							0b1010,
							0b1110,
						},
						'p', 'P' => .{
							0b1111,
							0b0101,
							0b0111,
						},
						'q', 'Q' => .{
							0b0111,
							0b0101,
							0b1111,
						},
						'r', 'R' => .{
							0b1111,
							0b0101,
							0b1011,
						},
						's', 'S' => .{
							0b1010,
							0b1101,
							0b1101,
						},
						't', 'T' => .{
							0b0001,
							0b1111,
							0b0001,
						},
						'u', 'U' => .{
							0b1111,
							0b1000,
							0b1111,
						},
						'v', 'V' => .{
							0b0111,
							0b1000,
							0b0111,
						},
						'w', 'W' => .{
							0b1111,
							0b0110,
							0b1111,
						},
						'x', 'X' => .{
							0b1010,
							0b0100,
							0b1010,
						},
						'y', 'Y' => .{
							0b1010,
							0b0100,
							0b0010,
						},
						'z', 'Z' => .{
							0b1101,
							0b1011,
							0b1011,
						},

						else => undefined,
					};
				}

				const id: u4 = @truncate(counter >> 2);

				const col1: u2 = @truncate(id     );
				const col2: u2 = @truncate(id >> 2);

				const background: led_matrix.Color = if (col1 == col2) .Black else @enumFromInt(@min(col1, col2));
				const foreground: led_matrix.Color =                               @enumFromInt(@max(col1, col2));

				var frame: led_matrix.Frame = undefined;

				for (bits, 1..) |px, y| {
					var pix = px;
					for (0..4) |x| {
						frame.pixels[3-y][3-x] = if (pix & 1 != 0) foreground else background;
						pix >>= 1;
					}
				}

				led_matrix.push_frame(frame);

				counter += 1;
			}
		},
		4 => {
			while (true) {
				var line = std.ArrayList(u8).empty;
				defer line.deinit(alloc);

				while (true) {
					const c = try uart2.reader.takeByte();

					if (c == '\n') break;
					if (c == '\r') break;

					try line.append(alloc, c);
				}

				try uart2.writer.print(":: {any}\n\r", .{line.items});
				try uart2.writer.flush();
			}
		},
		5 => {

			RCC.AHB2ENR.GPIOAEN = true;
			RCC.AHB2ENR.GPIOBEN = true;
			RCC.AHB2ENR.GPIOCEN = true;
			RCC.APB1ENR1.spi2_enable = true;

			GPIO_C.mode.pin_0x3 = .alt_func; // mosi pin
			GPIO_B.mode.pin_0xE = .alt_func; // miso pin
			GPIO_B.mode.pin_0xD = .alt_func; // sclk pin
			GPIO_B.mode.pin_0xB = .output; // latch pin

			GPIO_B.mode.pin_0xC = .output; // imu cs

			GPIO_C.alt_func.pin_0x3 = 5;
			GPIO_B.alt_func.pin_0xD = 5;
			GPIO_B.alt_func.pin_0xE = 5;

			GPIO_B.output.pin_0xC = true;

			const imu = hal.Imu{
				.spi = .{ .regs = SPI_2 },
				.cs_pin = .{
					.root_controller = GPIO_B,
					.pin_num = 0xC,
				},
			};

			imu.config_spi();


			delay();

			while (true) {
				const whoami = imu.get_reg(0x0f);

				std.log.info("whoami: 0x{x}", .{whoami});
				delay();

			}
		},
		else => { // echo
			while (true) {
				// Check if data was recieved
				if (USART_2.status.receive_ready) {
					// get data
					const c = USART_2.receive_data;

					// wait for transmitter to be ready
					while (!USART_2.status.transmit_ready) {}

					// send data
					USART_2.transmit_data = c;
				}
			}
		},
	}

}

