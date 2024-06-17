#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "helpers.h"
#include "ROM config.h"
#include "ROM.h"



#define __CODEHW SECTION("CODEHW")

#define INIT_STACK(x) __asm__ volatile ( "lda #>" x "\nsta _sp1\nlda #<" x "\nsta _sp0\n" : : : "a" )

// force strings into hardware window
#define DEFSTRING(n) SECTION("RODATAHW")  const char n[]

DEFSTRING(myhelp) = "TESTROM";

DEFSTRING(exthelp) = "\
  This ROM must be inserted in the\r  OS ROM socket (IC 51).\r\
  Visit www.boobip.com for more\r  information.\r";

__CODEHW
static void osasci(char c) {
	__asm__ __volatile__("jsr $ffe3" : : "Aq" (c));
}

__CODEHW
static void osnewl() {
	__asm__ __volatile__("jsr $ffe7" : : : "a");
}

__CODEHW
static inline uint8_t getcommandchar(uint8_t ofs) {
	uint8_t r;
	__asm__("lda ($f2),y" : "=Aq"(r) : "yq"(ofs));
	return r;
}


__CODEHW
static void swr_putc(char c) {
	osasci(c);
}

__CODEHW
static void swr_puts(const char* s) {
	while (*s) swr_putc(*s++);
}



__CODEHW
static void title(void)
{
	osnewl();
	swr_puts(ROMHeader.title);
	swr_putc(' ');
	swr_puts(ROMHeader.version);
	osnewl();
}



__CODEHW
void swr_help(uint8_t ofs)
{
	char a = getcommandchar(ofs);

	if (a == 0xd) {
		title();
		swr_putc(' ');
		swr_putc(' ');
		swr_puts(myhelp);
		osnewl();
	}
	else {
		bool found = false;
		char i = ofs;

		while (1)
		{
			char j = 0;
			char a, b, u;
			do {
				a = getcommandchar(i++);
				u = a & 0xdf;// get char as upper case
				b = myhelp[j++];
			} while (b && u == b);

			if (((b != 0) && (a == '.')) || ((b == 0) && (a <= 32)))
			{
				found = true;
				break;
			}

			while (a > ' ') a = getcommandchar(i++); // skip to next token
			if (a == 0xd) break;
		}

		if (found) {
			title();
			swr_puts(exthelp);
		}
	}
}
