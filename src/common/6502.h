#ifndef __6502_H__
#define __6502_H__

__attribute__((pure))
inline uint8_t _6502_mul10(uint8_t n)
{
	register uint8_t temp;
	register uint8_t x __asm__("a") = n;
	__asm__ __volatile__(
		"asl\n"
		"sta %1\n"
		"asl\n"
		"asl\n"
		"clc\n"
		"adc %1"
		: "=Aq" (x), "=r"(temp) : "Aq" (n));
	return x;
}



#endif // !__6502_H__
