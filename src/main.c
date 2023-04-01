#include <mystdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <stdint.h>

#include "common/basic2.h"
#include "common/os.h"
#include "common/6502.h"





// Set stack top
__asm__(".export __STACKTOP__: absolute = $3000\n");


void Init()
{

}


__attribute__((naked))
void reset_handler2()
{
	__asm__ __volatile__("lda #2");
	__asm__ __volatile__("sta $ff00");
	__asm__ __volatile__("jmp ($fffc)");
}

__attribute__((naked))
void reset_handler()
{
	char* dst = (char*)0;
	char* src = (void*)reset_handler2;
	for (uint8_t i = 0; i < 8; i++) dst[i] = src[i];
	__asm__ __volatile__("jmp 0");
}


uint8_t getstackpointer()
{
	register uint8_t regx __asm__("x");
	__asm__ __volatile__("tsx" : : "Aq" (regx));
	return regx;
}

int len = 10;

uint16_t** const vec_reset = (uint16_t**)0xfffc;

__attribute__((noreturn))
uint8_t main(int argc, char* argv)
{
	*vec_reset = (void*)reset_handler;
	uint8_t stackp = getstackpointer();

	while (1)
	{

		for (int i = 0; i < len; i++)
		{
			char* p = (char*)0x7c00;
			p[i]++;
		}

	}

}