#include <stdint.h>
#include <string.h>
#include <stdarg.h>

#include "hmi.h"

extern int _vsprintf(void (*outfn)(char), const char* fmt, va_list ap);





void putc_vdu(char c)
{
	if (c < 32) return; // don't print control codes
	const char* const font = (const char* const)0xf800;
	const char* f = font + (c & 0x7f) * 8;

	char* d = displaypointer;
	for (uint8_t i = 0; i < 8; i++) d[i] = (c & 0x80) ? ~f[i] : f[i];

	displaypointer += 8;;
}

void puts_vdu(const char* msg)
{
	while (*msg) putc_vdu(*msg++);
}

void puts_ser(const char* msg)
{
	while (*msg) putc_ser(*msg++);
	putc_ser('\r');
	putc_ser('\n');
}

void puts_vdu_ser(const char* msg)
{
	while (*msg) putc_vdu_ser(*msg++);
	putc_ser('\r');
	putc_ser('\n');
}

int printf(const char* fmt, ...) 
{
	va_list ap;
	int retcode;

	va_start(ap, fmt);
	retcode = _vsprintf(putc_vdu_ser, fmt, ap);
	va_end(ap);

	return retcode;
}

int printf_vdu(const char* fmt, ...)
{
	va_list ap;
	int retcode;

	va_start(ap, fmt);
	retcode = _vsprintf(putc_vdu, fmt, ap);
	va_end(ap);

	return retcode;
}

int printf_ser(const char* fmt, ...)
{
	va_list ap;
	int retcode;

	va_start(ap, fmt);
	retcode = _vsprintf(putc_ser, fmt, ap);
	va_end(ap);

	return retcode;
}


