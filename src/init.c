// Init & entry code

#include <stdint.h>
#include <string.h>

#include "helpers.h"
#include "zeropage.h"
#include "hardware.h"
#include "hmi.h"
#include "menu.h"

extern void main(void);
extern void nmi_handler(void);
extern void rst_handler(void);
extern void irq_handler(void);

#define __CODE SECTION("OVL0")



__CODE static void init_bss(void);
__CODE static void init_data(void);
__CODE static void init_display(void);
__CODE static void init_sound(void);
__CODE static void init_sysvia(void);
__CODE static void init_uservia(void);




__attribute__((naked))
void nmi_handler(void) {
	++nmicount_;
	__asm__("rti");
}

__attribute__((naked))
void irq_handler(void) {
	__asm__("pha\ntya\npha\ntxa\npha\ncld");


	if (sheila->system_via.ifr & 2) {
		volatile uint8_t* const p = (uint8_t*)0x1a;// 01;
		*p ^= 128; // trample some RAM

		//HACK:: trample some ZP for testing
//		if ((*p & 15) == 0)
//			__asm__("lda #128\neor $99\nsta $99");
//		if ((*p & 15) == 8)
//			__asm__("lda #1\neor $98\nsta $98");

	}
	sheila->system_via.ifr = 0x7f; // clear all interrupts?



	//	++irqcount_;
	__asm__("pla\ntax\npla\ntay\npla");
	__asm__("rti");
}

// arrived in C land. Zero page tested OK
//__attribute__((noreturn))
__CODE
void rst_handler_3(void) {
//	init_bss();
//	init_data();

	init_display();
	init_sysvia();

	init_sound();

//	int n=printf("*%x %-4x %08lx %p*\r\n", 0x12, 0x34, 0xb00b19UL, (void*)0xa );
//	printf("*%04d %4d %08ld %d*\r\n", n, -12, -12UL, 12 );
//	printf("*%08b %08o %08x", 0x123,0x123,0x123);

	FARJMP(main);
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
