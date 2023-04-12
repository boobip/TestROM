#ifndef __HMI_H__
#define __HMI_H__

#include "hardware.h"
#include "zeropage.h"

#include <string.h>

extern char* displaypointer;

static char* const screen_start_ = (char* const)0x1800;

static inline void set_screenstart(uint16_t p)
{
	p >>= 3;
	outb(&sheila->crtc.addr, 12); // high order 6 bitd
	outb(&sheila->crtc.reg, p >> 8);
	outb(&sheila->crtc.addr, 13); // low order 8 bits
	outb(&sheila->crtc.reg, p & 0xff);
}

static inline void set_disp(uint8_t x, uint8_t y)
{
	uint16_t ofs = y * 320 + x * 8;
	displaypointer = screen_start_ + ofs;
}

extern void putc_vdu(char c);
extern void puts_vdu(const char* msg);

static inline void putc_ser(char c) {
	while (!(inb(&sheila->acia.status) & 10));
	outb(&sheila->acia.txb, c);
}
extern void puts_ser(const char* msg);

static inline void putc_vdu_ser(char c) {
	putc_vdu(c);
	putc_ser(c);
}

extern void puts_vdu_ser(const char* msg);

extern int printf(const char* fmt, ...);
extern int printf_vdu(const char* fmt, ...);
extern int printf_ser(const char* fmt, ...);

static inline void cls(void) {
	memset(screen_start_, 0, 40 * 32 * 8);
}

// input functions
static inline char ser_isrxfull(void) { return inb(&sheila->acia.status) & 1; }
static inline char ser_get(void) { return inb(&sheila->acia.rxb); }
static inline char ser_getch(void) {
	while (!(inb(&sheila->acia.status) & 1));

	return inb(&sheila->acia.rxb);
}


#endif // !__HMI_H__
