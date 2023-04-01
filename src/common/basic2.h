#ifndef __BASICII_H__
#define __BASICII_H__

#include <stdint.h>

typedef struct {
	uint8_t sign;
	uint8_t exponentoverflow;
	uint8_t binaryexponent;
	uint8_t mantissa[4];
	uint8_t roundingbyte;
} _basic_fp_unpacked;

static uint32_t * const _basic_reg_inta = (uint32_t * const)0x2a;
static _basic_fp_unpacked * const _basic_reg_fpa = (_basic_fp_unpacked * const)0x2e;
static _basic_fp_unpacked * const _basic_reg_fpb = (_basic_fp_unpacked * const)0x3b;

static uint32_t* const _basic_reg_atpercent= (uint32_t*const)0x400;
static uint32_t* const _basic_reg_a = (uint32_t*const)0x404;


static uint32_t * const _basic_rand = (uint32_t * const)0xd;


static char* const _basic_string_p = (char*const)0x600;
static uint8_t* const _basic_print_flag = (uint8_t*const)0x15;
//static uint8_t* const _basic_string_count = (uint8_t*const)0x1e;
static uint8_t* const _basic_string_len = (uint8_t*const)0x36;


inline static void basic2_rndgen()
{
	__asm__ __volatile__("jsr $af87": : : "memory", "a", "y");
}

// BASIC2 convert number to string (hex). Number in IntA. String -> StrA
inline static void basic2_cntoshex()
{
	*_basic_string_len = 0;
	register char ntype __asm__("y") = 0x40;
	__asm__ __volatile__("jsr $9e90" : : "yq" (ntype) : "memory", "a", "x");
}

// BASIC2 convert number to string (hex). Number in IntA. String -> StrA
inline static void basic2_cntosdec()
{
	*_basic_print_flag = 0;
	register char ntype __asm__("y") = 0x40;
	__asm__ __volatile__("jsr $9edf" : : "yq" (ntype) : "memory", "a", "x");
}

// BASIC2 convert number to string (hex). Number in FpA. String -> StrA
inline static void basic2_cntosfp()
{
	//set %@
	register char ntype __asm__("y") = 0xff;
	__asm__ __volatile__("jsr $9edf" : : "yq" (ntype) : "memory", "a", "x");
}


extern void basic2_cntosudec();




inline static void basic2_rndseed(uint32_t Seed)
{
	uint8_t* const _rnd5 = (uint8_t*)0x11;

	*_basic_rand = Seed;
	*_rnd5 = 0x40; // do this because basic does it
}





#endif // !__BASICII_H__
