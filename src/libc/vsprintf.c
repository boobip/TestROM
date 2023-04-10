//#include <mystdio.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>

#include <stdbool.h>


typedef void (*pfnputc_t)(char);

static pfnputc_t outfn_ = 0; // static outfunction saves 200+ bytes of call overhead

static void outfn(char c)
{
	outfn_(c);
}


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

static uint8_t udectoa_count(uint32_t num)
{
	uint8_t c = 0;

	do {
		num /= 10;
		c++;
	} while (num);

	return c;
}

static void udectoa(uint32_t num)
{
	if (!num) {
		outfn('0');
	}
	else {
		bool leading = false;
		uint32_t t = 1000000000;

		do
		{
			uint8_t d = 0;

			d = num / t;
			num %= t;

			if ((d != 0) || leading) {
				outfn('0' + d);
				leading = true;
			}

			t /= 10;
		} while (t);
	}
}




static uint8_t hextoa_count(uint32_t num)
{
	uint8_t c = 0;
	do {
		num >>= 4;
		c++;
	} while (num);

	return c;
}

static void hextoa(uint32_t num)
{
	if (!num) {
		outfn('0');
	}
	else {
		bool leading = false;
		for (uint8_t i = 0; i < 8; i++)
		{
			//uint8_t d = (num >> 24);
			uint8_t d = ((uint8_t*)&num)[3]; // shorter but not good C

			d >>= 4; // want high nibble
			num <<= 4;

			if ((d != 0) || leading) {
				char a = d;
				a += (d > 9) ? 'A' - 10 : '0';

				outfn(a);
				leading = true;
			}
		}
	}
}




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
				len = udectoa_count(val) + (uint8_t)neg; // +1 char for minus symbol if necessary

				if (width > len && !leftjustify) {
					if (neg && pad == '0') outfn('-');
					RepeatChar(pad, width - len);
					if (neg && pad != '0') outfn('-');
				}
				udectoa(val);
			}
			break;

#if 0
			case 'e':
			case 'E':
			case 'f':
			case 'g':
			case 'G':
			case 'o':
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
			case 'p':
				if (width < 4) width = 4;
			case 'x':
			case 'X':
			{
				uint32_t val = (longint) ? va_arg(ap, uint32_t) : va_arg(ap, uint16_t);
				len = hextoa_count(val);
				if (width > len && !leftjustify) RepeatChar(pad, width - len);
				hextoa(val);
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
			nchar += (width > len) ? width : len;
		}
	}

	return nchar;
}

