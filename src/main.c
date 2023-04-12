#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "hmi.h"
#include "menu.h"


// Set stack top
//__asm__(".export __STACKTOP__: absolute = $3000\n");




void main(void)
{
	while (1)
	{
		char selection = 0;

		if (ser_isrxfull()) {
			char c = ser_get();
			set_disp(10,0);
			putc_vdu(c);

			if (c >= '0' && c <= '9') selection = c;
		}
		else
		{
			// check keyboard
		}

		if (selection) {
			CheckMenu(selection);
		}

		RenderMenu();

	}
	__builtin_unreachable();
}