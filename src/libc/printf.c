#include<mystdio.h>

void myputc(char c)
{
	if (c == '\n') osnewl();
	else oswrch(c);
}


int printf(const char *fmt, ...)
{
	va_list ap;
	int retcode;

	va_start(ap, fmt);
	retcode = _vsprintf(myputc, fmt, ap);
	va_end(ap);

	return retcode;
}

