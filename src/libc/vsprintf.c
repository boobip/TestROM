//#include <mystdio.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>

#include <stdbool.h>

#include "../zeropage.h"

extern void outfn(char c);

typedef void (*pfnputc_t)(char);


__attribute__((pure))
static char hextoascii(char radix, uint32_t num, char npad, char cpad)
{
	register char ret;
	register char r __asm("r0") = radix;
	register uint32_t n __asm("r1") = num;
	register char np __asm("r5") = npad;
	register char cp __asm("r6") = cpad;
	__asm volatile (
	"jsr hextoa; %0 %1 %2 %3 %4\n": "=Aq"(ret)
		: "r"(r), "r"(n), "r"(np), "r"(cp)
		);
	return ret;
}


__attribute__((pure))
static char dectoascii(bool neg, uint32_t num, char npad, char cpad)
{
	register char ret;
	register char r __asm("r0") = neg;
	register uint32_t n __asm("r1") = num;
	register char np __asm("r5") = npad;
	register char cp __asm("r6") = cpad;
	__asm volatile (
	"jsr dectoa; %0 %1 %2 %3 %4\n": "=Aq"(ret)
		: "r"(r), "r"(n), "r"(np), "r"(cp)
		);
	return ret;
}




/*
__attribute__((naked)) void outfn(char c) {
	__asm__(
		"jmp (%0)"::"m"(outfn_)
	);
}
*/

static const char* ReadFormatFlags(const char* fmt, char* pad, uint8_t* width, bool* leftjustify)
{
	while (1)
	{
		char c = *fmt;

		// is a width?
		if (c >= '1' && c <= '9')
		{
			*width = c - '0';
			while (1)
			{
				c = *(++fmt);
				uint8_t n = c - '0';
				if (n > 9) break;
				*width *= 10;
				*width += n;
			}
			continue;
		}

		// other flags
		switch (c)
		{
		case '-':
			*leftjustify = true;
			break;
		case '+':
		case ' ':
		case '#':
			// not implemented
			break;
		case '0':
			*pad = '0';
			break;
		case '\0':
		default:
			return fmt;
		}
		++fmt; // used up a character
	}
}



static const char* FormatPrecision(const char* fmt)
{
	// not implemented
	return fmt;
}

static void RepeatChar(char c, char n)
{
	while (n) {
		outfn(c);
		n--;
	}
}











//__attribute__((section("OVL1")))
int _vsprintf(pfnputc_t putc, const char* fmt, va_list ap)
{
	outfn_ = putc;
	int nchar = 0;
	while (1)
	{
		char c = *fmt;
		if (c == 0) break;
		++fmt;

		if (c != '%') {
			outfn(c);
			++nchar;
		}
		else
		{
			char pad = ' ';
			uint8_t width = 0;
			bool leftjustify = 0;
			bool longint = 0;
			bool unsignedint = 0;
			bool upper = 0;
			uint8_t len = 1;

			// flags
			fmt = ReadFormatFlags(fmt, &pad, &width, &leftjustify);

			// precision
			//fmt = FormatPrecision(fmt);

			// length
			if (longint = *fmt == 'l') ++fmt;

			c = *fmt;
			if (c <= 'Z' && c >= 'A') {
				c += 'a' - 'A'; upper = 1;
			}
			++fmt;
			switch (c)
			{
			case 'c':
				if (width > len && !leftjustify) RepeatChar(' ', width - len);
				outfn(va_arg(ap, uint16_t));
				break;
			case 'u':
				unsignedint = 1;
			case 'd':
			case 'i':
			{
				uint32_t val = (longint)
					? va_arg(ap, uint32_t)
					: (int32_t)va_arg(ap, int16_t);

				bool neg = false;
				if (!unsignedint && ((int32_t)val < 0)) {
					val = -(int32_t)val;
					neg = true;
				}
				len = dectoascii(neg, val, width, pad);
			}
			break;

#if 0
			case 'e':
			case 'E':
			case 'f':
			case 'g':
			case 'G':
				continue;
#endif // 0
			case 's':
			{
				const char* s = va_arg(ap, char*);
				int l = strlen(s);
				len = (l > 255) ? 255 : l; // only support 8 bit padding
				if (width > len && !leftjustify) RepeatChar(' ', width - len);
				while (*s) outfn(*s++);
			}
			break;
			case 'b':;
				uint8_t radix;
				radix = 1;		// binary
				goto basen;
			case 'o':
				radix = 0x3;	// octal
				goto basen;
			case 'p':
				if (width < 4) width = 4;
			case 'x':
				//case 'X':
				radix = 0xf;	// HEX
			basen:
			{
				uint32_t val = (longint) ? va_arg(ap, uint32_t) : va_arg(ap, uint16_t);
				uint8_t npad = (leftjustify) ? 0 : width;
				len = hextoascii(radix, val, npad, pad);
			}
			break;

#if 0
			case '*':
			case 'n':
				/* print nothing*/
				size_t * p = va_arg(ap, size_t*);
				feed pointer the number of chars printed so far
					continue;
#endif // 0
			case '%':
			default:
				outfn(c); // no padding on escaped %%
			}

			// pad right if required
			if (leftjustify && width > len) RepeatChar(' ', width - len);
			nchar += (len > width) ? len : width;
			}
		}

	return nchar;
	}

