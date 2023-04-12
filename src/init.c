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

static uint32_t irqcount = 0;
static uint32_t nmicount = 0;

static void init_bss(void);
static void init_data(void);
static void init_display(void);
static void init_sound(void);
static void init_sysvia(void);
static void init_uservia(void);




__attribute__((naked))
void nmi_handler(void) {
	++nmicount;
	__asm__("rti");
}

__attribute__((naked))
void irq_handler(void) {
	__asm__("pha\ntya\npha\ntxa\npha");


	if (sheila->system_via.ifr & 2) {
		volatile uint8_t* const p = (uint8_t*)0x1a01;
		*p +=1; // trample some RAM

	}
	sheila->system_via.ifr = 0x7f; // clear all interrupts?

//	++irqcount;
	__asm__("pla\ntax\npla\ntay\npla");
	__asm__("rti");
}





// arrived in C land. Zero page tested OK
//__attribute__((noreturn))
void rst_handler_3(void) {
	init_bss();
	init_data();

	init_display();
	init_sound();

	init_sysvia();

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

	set_disp(10, 10);
	putc_vdu('A' | 0x80);
	puts_vdu("Hello World\n");

	set_disp(0, 0);
	puts_vdu("Welcome!");
}

void init_sound(void) {
	sheila->system_via.ddra = 0xff; // all outputs
	sheila->system_via.ddrb = 0x0f; // bits 0-3 outputs

	sheila->system_via.ora = 0x0; // 

	for (char i = 0; i < 8; i++)
	{
		sheila->system_via.orb = i | 8; // set all things on slow bus select to 1
	}


	for (char i = 0; i < 4; i++)
	{
		sheila->system_via.ora = ((2 * i + 1) << 4) | 0x80 | 0xf; // volume to zero
		sheila->system_via.orb = 0x00; // 
		__asm__ __volatile__("jsr nopslide8");
		sheila->system_via.orb = 0x08; // 
		__asm__ __volatile__("jsr nopslide8");

	}




}


void init_sysvia(void)
{
	sheila->system_via.pcr = 0;
	sheila->system_via.ier = 0x7f; // disable all interrupts
	sheila->system_via.ier = 0x80 | 2; // enable CA1 interrupt VSYNC
	__asm__("cli"); // bodge interrupts back on
}
void init_uservia(void)
{

}
