#ifndef __C_LIB_MYSTDIO__
#define __C_LIB_MYSTDIO__

#include <stdint.h>

#include "../machine.h"

#include <stdio.h>

extern void myputc(char c);

//inline static int fputc(char c, FILE* F)
//{
//	if (c == '\n') osnewl();
//	else oswrch(c);
//	return 1;
//}

inline static void puts_basicstringbuffer()
{
	for (uint8_t i = 0; i < *_basic_string_len; ++i)
	{
		char c = _basic_string_p[i];
		if (c == '\n') osnewl();
		else oswrch(c);
	}
}

extern int printf(const char *fmt, ...);// __attribute__((format(printf, 1, 2))); doesn't seem to do anything

typedef void(*pfnputc_t)(char);

extern int _vsprintf(pfnputc_t outfn, const char * fmt, va_list ap);






#endif // !__C_LIB_MYSTDIO__
