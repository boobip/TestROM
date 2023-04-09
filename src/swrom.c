#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "ROM config.h"
#include "ROM.h"


static const char** const _os_zp_commandpointer = (const char**)0xf2;

#define SECTION(x) __attribute__((section(x)))
#define INIT_STACK(x) __asm__ volatile ( "lda #>" x "\nsta _sp1\nlda #<" x "\nsta _sp0\n" : : : "a" )

// force strings into hardware window
#define DEFSTRING(n) SECTION("RODATAHW")  const char n[]

DEFSTRING(myhelp) = "TESTROM";
DEFSTRING(exthelp) = "\
  This ROM must be inserted in the\r  OS ROM socket (IC 51).\r\
  Visit www.boobip.com for more\r  information.\r";

SECTION("CODEHW")
static void osasci(char c) {
	__asm__ __volatile__("jsr $ffe3" : : "Aq" (c));
}

SECTION("CODEHW")
static void osnewl() {
	__asm__ __volatile__("jsr $ffe7" : : : "a");
}

SECTION("CODEHW")
static int strncmp(const char* s1, const char* s2, size_t n)
{
	unsigned int i;

	for (i = 0; i < n && (*s1 || *s2); i++, s1++, s2++)
	{
		int diff;

		if (!*s1 || !*s2)
			return *(unsigned char*)s1 - *(unsigned const char*)s2;

		diff = *s1 - *s2;
		if (diff != 0)
			return diff;
	}

	return 0;
}



SECTION("CODEHW")
static void swr_putc(char c)
{
	osasci(c);
}

SECTION("CODEHW")
static void swr_puts(const char* s)
{
	while (*s) swr_putc(*s++);
}



SECTION("CODEHW")
static void title(void)
{
	osnewl();
	swr_puts(ROMHeader.title);
	swr_putc(' ');
	swr_puts(ROMHeader.version);
	osnewl();
}



SECTION("CODEHW")
void swr_help(uint8_t ofs)
{
	const char* p = *_os_zp_commandpointer;
	p += ofs;

	if (*p == 0xd) {
		title();
		swr_putc(' ');
		swr_puts(myhelp);
		osnewl();
	}
	else {
		bool found = false;

		while (1)
		{
			char c = *p;

			if (c == 0xd) break;
			if (c == '.') {
				found = true;
				break;
			}

			if (c == *myhelp) {
				uint8_t len = sizeof(myhelp) - 1;
				int r = strncmp(myhelp, p, len);
				char e = p[len];
				if (r == 0 && (e == 0xd || e == ' ')) {
					found = true;
					break;
				}
			}

			while (!(*p == ' ' || *p == 0xd)) p++; // no match, eat token
			++p;
		}

		if (found) {
			title();
			swr_puts(exthelp);
		}
	}
}
