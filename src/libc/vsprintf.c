#include <mystdio.h>
#include <string.h>

#include<stdbool.h>



#if 0
static void EmitChar(char c)
{
	_basic_string_p[*_basic_string_len] = c;
	++*_basic_string_len;
}

static void EmitString(const char* s)
{
	while (*s != 0)
	{
		_basic_string_p[*_basic_string_len] = *(s++);
		++*_basic_string_len;
	}
}

static void EmitLeftPad(uint8_t start, uint8_t width, char padc)
{
	uint8_t last = *_basic_string_len;
	uint8_t e = start + width;
	if (last >= e) return; // nothing to do

	uint8_t pad = e - last;
	int8_t len = width - pad;

	for (int8_t i = 1; i <= len; ++i) _basic_string_p[e - i] = _basic_string_p[last - i];// move string over
	for (uint8_t i = 0; i < pad; i++) _basic_string_p[start + i] = padc; // pad

	*_basic_string_len = e; // set new end
}

static void EmitRightPad(uint8_t start, uint8_t width, char padc)
{
	uint8_t last = *_basic_string_len;
	uint8_t e = start + width;
	if (last >= e) return; // nothing to do
	uint8_t pad = e - last;
	while (pad--) EmitChar(padc);
}
#endif // 0

static inline const char* ReadFormatFlags(const char* fmt, char* pad, uint8_t* width, bool* leftjustify)
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



inline const char* FormatPrecision(const char* fmt)
{
	// not implemented
	return fmt;
}

static inline void RepeatChar(char c, char n, pfnputc_t outfn)
{
	for (char i = 0; i < n; i++) outfn(c);
}



//#define ROM

static inline char* udectoa(uint32_t num)
{
#ifdef ROM
	char*p = _basic_string_p + 0xff;
	*p = 0;
	if (!num) *--p = '0';
	for (; !!num; num /= 10)
	{
		--p;
		char d = num % 10;
		*p = d + '0';
	}
	return p;
#else
	basic2_cntosudec(); // use BASIC to format it
	_basic_string_p[*_basic_string_len] = 0;
	return _basic_string_p;
#endif // ROM
}


static inline char* idectoa(int32_t num)
{
#ifdef ROM
	bool neg = (num < 0);
	if (neg) num = -num;

	char*p = udectoa(num);
	if (neg)
	{
		--p;
		*p = '-';
	}
	return p;
#else
	basic2_cntosdec(); // use BASIC to format it
	_basic_string_p[*_basic_string_len] = 0;
	return _basic_string_p;
#endif // ROM
}


static inline char* hextoa(uint32_t num)
{
#ifdef ROM
	char*p = _basic_string_p + 0xff;
	*p = 0;
	if (!num) *--p = '0';
	for (; !!num; num >>= 4)
	{
		--p;
		char d = num & 0xf;
		d += (d > 9) ? 'A' - 10 : '0';
		*p = d;
	}
	return p;
#else
	basic2_cntoshex(); // use BASIC to format it
	_basic_string_p[*_basic_string_len] = 0;
	return _basic_string_p;
#endif // ROM
}


int _vsprintf(pfnputc_t outfn, const char * fmt, va_list ap)
{

	int nchar = 0;
	while (1)
	{
		char c = *fmt;
		if (c == 0) return nchar;
		++fmt;
		//if (c == '\r') continue;
		if (c != '%') {
			outfn(c);
			//++nchar;
		}
		else
		{
			char pad = ' ';
			uint8_t width = 0;
			bool leftjustify = 0;
			bool longint = 0;
			bool unsignedint = 0;
			bool upper = 0;

			// flags
			fmt = ReadFormatFlags(fmt, &pad, &width, &leftjustify);

			// precision
			//fmt = FormatPrecision(fmt);

			// length
			if (longint = *fmt == 'l') ++fmt;

			const char* pout = _basic_string_p;

			c = *fmt;
			if (c <= 'Z'&&c >= 'A') {
				c += 'a' - 'A'; upper = 1;
			}
			++fmt;
			switch (c)
			{
			case 'c':
				_basic_string_p[0] = va_arg(ap, uint16_t);
				_basic_string_p[1] = 0;
				break;
			case 'u':
				unsignedint = 1;
			case 'd':
			case 'i':
				if (!longint) *((int32_t*)_basic_reg_inta) = va_arg(ap, int16_t);
				else *_basic_reg_inta = va_arg(ap, uint32_t);
				pout = (unsignedint) ? udectoa(*_basic_reg_inta) : idectoa(*_basic_reg_inta);
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
				pout = va_arg(ap, char*);
				break;
			case 'p':
				if (width < 4) width = 4;
			case 'x':
			case 'X':
			{
				if (!longint) *_basic_reg_inta = va_arg(ap, uint16_t);
				else *_basic_reg_inta = va_arg(ap, uint32_t);
				pout = hextoa(*_basic_reg_inta);
				break;
			}

#if 0
			case '*':
			case 'n':
				/* print nothing*/
				size_t* p = va_arg(ap, size_t*);
				feed pointer the number of chars printed so far
					continue;

#endif // 0
			case '%':
			default:
				_basic_string_p[0] = c;
				_basic_string_p[1] = 0;
				break;
			}

			// count length for padding
			char len = width;
			for (char i = 0; i < width; i++)
				if (pout[i] == 0)
				{
					len = i;
					break;
				}

			// pad left if required
			if (width > len && !leftjustify) RepeatChar(pad, width - len, outfn);

			// output string
			while (*pout) outfn(*(pout++));

			// pad right if required
			if (leftjustify && width > len) RepeatChar(' ', width - len, outfn);
		}
	}

	//return nchar;
}

