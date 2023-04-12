// Init & entry code

#include <stdint.h>
#include <string.h>
#include "zeropage.h"
#include "hardware.h"
#include "hmi.h"
#include "menu.h"

extern void main(void);
extern void nmi_handler(void);
extern void rst_handler(void);
extern void irq_handler(void);


typedef struct {
	void* nmi;
	void* rst;
	void* irq;
} vtable_t;


__attribute__((section("VECTORS")))
vtable_t _vtable = {
	nmi_handler,
	rst_handler,
	irq_handler
};

ZPBSS static uint32_t irqcount_ = 0;
ZPBSS static uint32_t nmicount_ = 0;

static void init_bss(void);
static void init_data(void);
static void init_display(void);
static void init_sound(void);
static void init_sysvia(void);
static void init_uservia(void);




__attribute__((naked))
void nmi_handler(void) {
	++nmicount_;
	__asm__("rti");
}

__attribute__((naked))
void irq_handler(void) {
	__asm__("pha\ntya\npha\ntxa\npha");


	if (sheila->system_via.ifr & 2) {
		volatile uint8_t* const p = (uint8_t*)0x1a01;
		*p += 1; // trample some RAM

	}
	sheila->system_via.ifr = 0x7f; // clear all interrupts?

	//	++irqcount_;
	__asm__("pla\ntax\npla\ntay\npla");
	__asm__("rti");
}





// arrived in C land. Zero page tested OK
//__attribute__((noreturn))
void rst_handler_3(void) {
	init_bss();
	init_data();

	init_display();
	init_sysvia();

	init_sound();


	main();
	__builtin_unreachable();
}




void init_bss(void)
{
	extern char __BSS_RUN__;
	extern char __BSS_SIZE__;
	memset(&__BSS_RUN__, 0, (uint16_t)&__BSS_SIZE__);
	memset((void*)0x90, 0, 0x70);
}

void init_data(void)
{
	extern char __DATA_RUN__;
	extern char __DATA_LOAD__;
	extern char __DATA_SIZE__;
	memcpy(&__DATA_RUN__, &__DATA_LOAD__, (uint16_t)&__DATA_SIZE__);
}


void init_display(void) {
	set_screenstart(0x1800U);
}

void init_sound(void) {
	// silence all channels
	for (char c = 0; c < 4; c++)
	{
		uint8_t vol = ((2 * c + 1) << 4) | 0x80 | 0xf; // volume to zero
		slowbus_sn76489_write(vol);
	}
}


void init_sysvia(void)
{
	// set up slow bus
	outb(&sheila->system_via.ddra, 0xff); // all outputs
	outb(&sheila->system_via.ddrb, 0x0f); // bits 0-3 outputs
	outb(&sheila->system_via.ora, 0x0); // 

	for (char i = 0; i < 8; i++) slowbus1(i); // set all things on slow bus to 1



	outb(&sheila->system_via.pcr, 0x05); // posedge interrupt on CA1 & CA2
	outb(&sheila->system_via.ier, 0x7f); // disable all interrupts
	outb(&sheila->system_via.ier, 0x80 | 2); // enable CA1 interrupt VSYNC
	__asm__("cli"); // bodge interrupts back on
}
void init_uservia(void)
{

}
