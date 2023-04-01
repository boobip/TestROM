#ifndef __OS_H__
#define __OS_H__

#include <stdint.h>
#include "bbcb.h"

static const char**const _os_zp_commandpointer = (const char**)0xf2;
static uint8_t*const _os_zp_selectedrom = (uint8_t*)0xf4;

static inline void osasci(char c)
{
	__asm__ __volatile__("jsr $ffe3" : : "Aq" (c));
}

inline void osnewl()
{
	__asm__ __volatile__("jsr $ffe7" : : : "a");
}

inline void oswrch(char c)
{
	// OSWRCH
	register char x __asm__("a") = c;
	__asm__ __volatile__("jsr $ffee" : : "Aq" (x));
}




static inline void osbyte(uint8_t func, uint8_t* x, uint8_t*y)
{
	__asm__ __volatile__("jsr $fff4" : "+xq"(*x), "+yq"(*y) : "Aq" (func));
}


inline void os_mode(uint8_t n)
{
	//VDU22,n
	oswrch(22);
	oswrch(n);
}

static inline uint8_t os_osbyte_ReadBasicRomNumber()
{
	uint8_t x = 0, y = 0xff;
	osbyte(0xbb, &x, &y);
	return x;
}


inline static void os_SelectRomFromCopy() { hw_SetRomsel(*_os_zp_selectedrom); } // 
inline static void os_selectROM(uint8_t bank) {
	*_os_zp_selectedrom = bank;
	hw_SetRomsel(bank);
}


#endif // !__OS_H__

