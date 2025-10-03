MEMORY {
	flash (rx!w) : ORIGIN = 0x08000000, LENGTH = 0x00100000
	sram2 (rwx)  : ORIGIN = 0x10000000, LENGTH = 0x00008000 /* fast, high performance ram */
	sram1 (rwx)  : ORIGIN = 0x20000000, LENGTH = 0x00018000 /* slower ram, invalidated on standby */
}

_estack = ORIGIN(sram2) + LENGTH(sram2);

_sheap = ORIGIN(sram1);
_eheap = ORIGIN(sram1) + LENGTH(sram1);

SECTIONS {
	.isr_vector : {
		KEEP(*(.isr_vector))
	} > flash

	.text : {
		*(.text*)
		*(.srodata*)
		*(.rodata*)
	} > flash

	.ARM.extab : {
		*(.ARM.extab* .gnu.linkonce.armextab.*)
	} > flash

	.ARM.exidx : {
		*(.ARM.exidx* .gnu.linkonce.armexidx.*)
	} > flash

	.data : {
		. = ALIGN(4);
		_sdata = .;

		*(.sdata*)
		*(.data*)

		. = ALIGN(4);
		_edata = .;
	} > sram2 AT> flash

	.bss (NOLOAD): {
		. = ALIGN(4);
		_sbss = .;

		*(.sbss*)
		*(.bss*)

		. = ALIGN(4);
		_ebss = .;
	} > sram2


	_mdata = LOADADDR(.data);
}

