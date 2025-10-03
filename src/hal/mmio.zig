
fn sanity_check(comptime T: type, comptime field: []const u8, comptime offset: usize) void {
	const std = @import("std");
	const actual: usize = @offsetOf(T, field);
	if (actual != offset) {

		const should_hex = comptime std.fmt.comptimePrint("0x{x}", .{offset});
		const actual_hex = comptime std.fmt.comptimePrint("0x{x}", .{actual});

		const err1 = "[ SANITY CHECK FAILED ] The field '" ++ field ++ "' of the passed struct";
		const err2 = "should have offset " ++ should_hex ++ ", but has " ++ actual_hex ++ " instead!";

		const err = err1 ++ " " ++ err2;

		@compileError(err);
	}
}


pub const VectorTable = extern struct {

	fn unhandler() callconv(.c) noreturn {
		while (true) {}
	}

	const Handler = extern union {
		naked: *const fn () callconv(.naked) void,
		c: *const fn () callconv(.c) void,
	};
	const unhandled = Handler{ .c = &unhandler };

	initial_stack_pointer: *const anyopaque,
	Reset: Handler,
	NMI: Handler = unhandled,
	HardFault: Handler = unhandled,
	MemManageFault: Handler = unhandled,
	BusFault: Handler = unhandled,
	UsageFault: Handler = unhandled,

	_reserved5: [4]u32 = undefined,

	SVCall: Handler = unhandled,

	_reserved10: [2]u32 = undefined,

	PendSV: Handler = unhandled,
	SysTick: Handler = unhandled,
	WWDG: Handler = unhandled,
	PVD_PVM: Handler = unhandled,
	TAMP_STAMP: Handler = unhandled,
	RTC_WKUP: Handler = unhandled,
	FLASH: Handler = unhandled,
	RCC: Handler = unhandled,
	EXTI0: Handler = unhandled,
	EXTI1: Handler = unhandled,
	EXTI2: Handler = unhandled,
	EXTI3: Handler = unhandled,
	EXTI4: Handler = unhandled,
	DMA1_CH1: Handler = unhandled,
	DMA1_CH2: Handler = unhandled,
	DMA1_CH3: Handler = unhandled,
	DMA1_CH4: Handler = unhandled,
	DMA1_CH5: Handler = unhandled,
	DMA1_CH6: Handler = unhandled,
	DMA1_CH7: Handler = unhandled,
	ADC1_2: Handler = unhandled,
	CAN1_TX: Handler = unhandled,
	CAN1_RX0: Handler = unhandled,
	CAN1_RX1: Handler = unhandled,
	CAN1_SCE: Handler = unhandled,
	EXTI9_5: Handler = unhandled,
	TIM1_BRK_TIM15: Handler = unhandled,
	TIM1_UP_TIM16: Handler = unhandled,
	TIM1_TRG_COM_TIM17: Handler = unhandled,
	TIM1_CC: Handler = unhandled,
	TIM2: Handler = unhandled,
	TIM3: Handler = unhandled,
	TIM4: Handler = unhandled,
	I2C1_EV: Handler = unhandled,
	I2C1_ER: Handler = unhandled,
	I2C2_EV: Handler = unhandled,
	I2C2_ER: Handler = unhandled,
	SPI1: Handler = unhandled,
	SPI2: Handler = unhandled,
	USART1: Handler = unhandled,
	USART2: Handler = unhandled,
	USART3: Handler = unhandled,
	EXTI15_10: Handler = unhandled,
	RTC_ALARM: Handler = unhandled,
	DFSDM1_FLT3: Handler = unhandled,
	TIM8_BRK: Handler = unhandled,
	TIM8_UP: Handler = unhandled,
	TIM8_TRG_COM: Handler = unhandled,
	TIM8_CC: Handler = unhandled,
	ADC3: Handler = unhandled,
	FMC: Handler = unhandled,
	SDMMC1: Handler = unhandled,
	TIM5: Handler = unhandled,
	SPI3: Handler = unhandled,
	UART4: Handler = unhandled,
	UART5: Handler = unhandled,
	TIM6_DACUNDER: Handler = unhandled,
	TIM7: Handler = unhandled,
	DMA2_CH1: Handler = unhandled,
	DMA2_CH2: Handler = unhandled,
	DMA2_CH3: Handler = unhandled,
	DMA2_CH4: Handler = unhandled,
	DMA2_CH5: Handler = unhandled,
	DFSDM1_FLT0: Handler = unhandled,
	DFSDM1_FLT1: Handler = unhandled,
	DFSDM1_FLT2: Handler = unhandled,
	COMP: Handler = unhandled,
	LPTIM1: Handler = unhandled,
	LPTIM2: Handler = unhandled,
	OTG_FS: Handler = unhandled,
	DMA2_CH6: Handler = unhandled,
	DMA2_CH7: Handler = unhandled,
	LPUART1: Handler = unhandled,
	QUADSPI: Handler = unhandled,
	I2C3_EV: Handler = unhandled,
	I2C3_ER: Handler = unhandled,
	SAI1: Handler = unhandled,
	SAI2: Handler = unhandled,
	SWPMI1: Handler = unhandled,
	TSC: Handler = unhandled,
	LCD: Handler = unhandled,

	_reserved93: [1]u32 = undefined,

	RNG: Handler = unhandled,
	FPU: Handler = unhandled,
	CRS: Handler = unhandled,
};


pub const GpioModes = enum(u2) {
	input    = 0b00,
	output   = 0b01,
	alt_func = 0b10,
	analog   = 0b11,
};

pub const GPIO_MODER = packed struct(u32) {
	pin_0x0: GpioModes,
	pin_0x1: GpioModes,
	pin_0x2: GpioModes,
	pin_0x3: GpioModes,
	pin_0x4: GpioModes,
	pin_0x5: GpioModes,
	pin_0x6: GpioModes,
	pin_0x7: GpioModes,
	pin_0x8: GpioModes,
	pin_0x9: GpioModes,
	pin_0xA: GpioModes,
	pin_0xB: GpioModes,
	pin_0xC: GpioModes,
	pin_0xD: GpioModes,
	pin_0xE: GpioModes,
	pin_0xF: GpioModes,
};

pub const GPIO_ODR = packed struct(u32) {
	pin_0x0: bool,
	pin_0x1: bool,
	pin_0x2: bool,
	pin_0x3: bool,
	pin_0x4: bool,
	pin_0x5: bool,
	pin_0x6: bool,
	pin_0x7: bool,
	pin_0x8: bool,
	pin_0x9: bool,
	pin_0xA: bool,
	pin_0xB: bool,
	pin_0xC: bool,
	pin_0xD: bool,
	pin_0xE: bool,
	pin_0xF: bool,

	_padding: u16,
};

pub const GPIO_Regs = packed struct {
	mode: GPIO_MODER,
	_otyper: u32,
	_ospeedr: u32,
	_pupdr: u32,
	_idr: u32,
	output: GPIO_ODR,
	_bsrr: u32,
	_lckr: u32,

	alt_func: packed struct(u64) {
		pin_0x0: u4,
		pin_0x1: u4,
		pin_0x2: u4,
		pin_0x3: u4,
		pin_0x4: u4,
		pin_0x5: u4,
		pin_0x6: u4,
		pin_0x7: u4,
		pin_0x8: u4,
		pin_0x9: u4,
		pin_0xA: u4,
		pin_0xB: u4,
		pin_0xC: u4,
		pin_0xD: u4,
		pin_0xE: u4,
		pin_0xF: u4,
	},

	_brr: u32,
	_ascr: u32,

};




pub const USART = packed struct {
	//_CR1: USART_CR1,
	//_CR2: u32,
	//_CR3: u32,
	control: packed struct(u96) { // CR1, CR2 & CR3
		enable: bool, // UE

		_UESM:   bool,

		receiver_enable: bool, // RE
		transmitter_enable: bool, // TE

		_IDLEIE: bool,
		_RXNEIE: bool,
		_TCIE:   bool,
		_TXEIE:  bool,
		_PEIE:   bool,
		_PS:     bool,
		_PCE:    bool,
		_WAKE:   bool,
		_M0:     bool,
		_MME:    bool,
		_CMIE:   bool,
		_OVER8:  bool,

		_DEDT: u5,
		_DEAT: u5,

		_RTOIE: bool,
		_EOBIE: bool,
		_M1:    bool,

		_padding1: u3,
		_CR2: u32,
		_CR3: u32,
	},

	//_BRR: USART_BRR,
	baudrate_div: u16, // BRR
	_padding1: u16,

	_GTPR: u32,
	_RTOR: u32,
	_RQR: u32,
	status: packed struct(u32) { //ISR
		_PE:    bool,
		_FE:    bool,
		_NF:    bool,
		_ORE:   bool,
		_IDLE:  bool,
		receive_ready: bool, // RXNE
		_TC:    bool,
		transmit_ready: bool, // TXE
		_LBDF:  bool,
		_CTSIF: bool,
		_CTS:   bool,
		_RTOF:  bool,
		_EOBF:  bool,

		_padding1: u1,

		_ABRE:  bool,
		_ABRF:  bool,
		_BUSY:  bool,
		_CMF:   bool,
		_SBKF:  bool,
		_RWU:   bool,
		_WUF:   bool,
		_TEACK: bool,
		_REACK: bool,

		_padding2: u2,

		_TCBGT: bool,

		_padding3: u6,
	},
	_ICR: u32,

	//_RDR: u32,
	receive_data: u9, //RDR
	_padding2: u23,

	//_TDR: USART_TDR,
	transmit_data: u9, // TDR
	_padding3: u23,

};



pub const SPI = packed struct {
	config: packed struct(u64) { // CR1 & CR2
		// CR1
		_CPHA: u1,
		_CPOL: u1,
		role: enum(u1) { // MSTR
			slave = 0,
			master = 1,
		},

		baudrate: enum(u3) { // BR
			div_2   = 0,
			div_4   = 1,
			div_8   = 2,
			div_16  = 3,
			div_32  = 4,
			div_64  = 5,
			div_128 = 6,
			div_256 = 7,
		},

		enable: bool, // SPE

		bit_order: enum(u1) {
			msb_first = 0,
			lsb_first = 1,
		},
		_SSI: u1,
		_SSM: u1,
		_RXONLY: u1,
		_CRCL: u1,
		_CRCNEXT: u1,
		_CRCEN: u1,
		_BIDIOE: u1,
		_BIDIMODE: u1,

		_padding1: u16,


		// CR2
		_RXDMAEN: u1,
		_TXDMAEN: u1,
		_SSOE: u1,
		_NSSP: u1,
		_FRF: u1,
		_ERRIE: u1,
		_RXNEIE: u1,
		_TXEIE: u1,

		data_size: enum(u4) { // DS
			//Not used = 0b0000,
			//Not used = 0b0001,
			//Not used = 0b0010,
			bits_4  = 0b0011,
			bits_5  = 0b0100,
			bits_6  = 0b0101,
			bits_7  = 0b0110,
			bits_8  = 0b0111,
			bits_9  = 0b1000,
			bits_10 = 0b1001,
			bits_11 = 0b1010,
			bits_12 = 0b1011,
			bits_13 = 0b1100,
			bits_14 = 0b1101,
			bits_15 = 0b1110,
			bits_16 = 0b1111,
		},

		_FRXT: u1,
		_LDMA_RX: u1,
		_LDMA_TX: u1,

		_padding2: u17,
	},

	status: packed struct(u16) {
		receive_ready: bool, // RXNE
		transmit_ready: bool, // TXE

		_padding1: u2,

		_CRCERR: bool,
		_MODF: bool,
		_OVR: bool,
		_BSY: bool,
		_FRE: bool,

		_FRLVL: u2,
		_FTLVL: u2,

		_padding2: u3,
	},
	_padding1: u16,

	data: packed union { // DR
		bits_4:  u4,
		bits_5:  u5,
		bits_6:  u6,
		bits_7:  u7,
		bits_8:  u8,
		bits_9:  u9,
		bits_10: u10,
		bits_11: u11,
		bits_12: u12,
		bits_13: u13,
		bits_14: u14,
		bits_15: u15,
		bits_16: u16,
	},
	_padding2: u16,
	
	_CRCPR: u16,
	_padding3: u16,

	_RXCRCR: u16,
	_padding4: u16,

	_TXCRCR: u16,
	_padding5: u16,

};


pub const RCC = packed struct {
	_CR: u32,
	_ICSCR: u32,
	_CFGR: u32,
	_PLLCFGR: u32,
	_PLLSAI1CFGR: u32,
	_PLLSAI2CFGR: u32,
	_CIER: u32,
	_CIFR: u32,
	_CICR: u32,

	_padding1: u32,

	_AHB1RSTR: u32,
	_AHB2RSTR: u32,
	_AHB3RSTR: u32,

	_padding2: u32,

	_APB1RSTR1: u32,
	_APB1RSTR2: u32,
	_APB2RSTR: u32,

	_padding3: u32,

	_AHB1ENR: u32,
	AHB2ENR: packed struct(u32) {
		GPIOAEN: bool,
		GPIOBEN: bool,
		GPIOCEN: bool,
		GPIODEN: bool,
		GPIOEEN: bool,
		GPIOFEN: bool,
		GPIOGEN: bool,
		GPIOHEN: bool,
		GPIOIEN: bool,

		_padding1: u3,

		OTGFSEN: bool,
		ADCEN:   bool,
		DCMIEN:  bool,

		_padding2: u1,

		AESEN:  bool,
		HASHEN: bool,
		RNGEN:  bool,

		_padding3: u13,
	},
	_AHB3ENR: u32,

	_padding4: u32,

	APB1ENR1: packed struct(u32) {
		timer_2_enable: bool,
		timer_3_enable: bool,
		timer_4_enable: bool,
		timer_5_enable: bool,
		timer_6_enable: bool,
		timer_7_enable: bool,

		_padding1: u3,

		_LCDEN: bool,
		_RTCAPBEN: bool,
		_WWDGEN: bool,

		_padding2: u2,

		spi2_enable: bool,
		spi3_enable: bool,

		_padding3: u1,

		uart_2_enable: bool,
		uart_3_enable: bool,
		uart_4_enable: bool,
		uart_5_enable: bool,

		i2c_1_enable: bool,
		i2c_2_enable: bool,
		i2c_3_enable: bool,

		_CRSEN: bool,

		can_1_enable: bool,
		can_2_enable: bool,

		_padding4: u1,

		_PWREN: bool,
		_DAC1EN: bool,
		_OPAMPEN: bool,
		_LPTIM1EN: bool,
	},
	_APB1ENR2: u32,
	_APB2ENR: u32,

	_padding5: u32,

	_AHB1SMENR: u32,
	_AHB2SMENR: u32,
	_AHB3SMENR: u32,

	_padding6: u32,

	_APB1SMENR1: u32,
	_APB1SMENR2: u32,
	_APB2SMENR: u32,

	_padding7: u32,

	_CCIPR: u32,

	_padding8: u32,

	_BDCR: u32,
	_CSR: u32,
	_CRRCR: u32,
	_CCIPR2: u32,
};
comptime { sanity_check(RCC, "_CCIPR2", 0x9c); }


