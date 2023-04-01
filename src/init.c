// Init & entry code

#include <stdint.h>
#include <string.h>

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


__attribute__((naked))
void nmi_handler(void) {
	__asm__("rti");
}

void init_bss(void);

void rst_handler_3(void) {
	volatile char* const screen = (char* const)0x7c00;

	init_bss();
	irqcount = 0;

	while (1)
	{

		for (int i = 0; i < 100; i++)
		{
			screen[i]++;
		}
	}

	__builtin_unreachable();
}


__attribute__((naked))
void irq_handler(void) {
	++irqcount;
	__asm__("rti");
}



void init_bss(void)
{
	extern char __BSS_RUN__;
	extern char __BSS_SIZE__;
	memset(&__BSS_RUN__, 0, (uint16_t)&__BSS_SIZE__);
}
