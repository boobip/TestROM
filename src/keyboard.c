#include <stdint.h>

#include "hardware.h"
#include "zeropage.h"
#include "hmi.h"

void keyboardscan();


uint8_t keypress_[128] = { 0 };
ZPBSS uint8_t currentkey_ = 0;
ZPBSS uint8_t lastkey_ = 0;

const char kb2ascii_[] = {
   81, 51, 52, 53, 0, 56, 0, 45, 94, 136,
   0, 87, 69, 84, 55, 73, 57, 48, 95, 138,
   49, 50, 68, 82, 54, 85, 79, 80, 91, 139,
   0, 65, 88, 70, 89, 74, 75, 64, 58, 13,
   0, 83, 67, 71, 72, 78, 76, 59, 93, 127,
   9, 90, 32, 86, 66, 77, 44, 46, 47, 135,
   27, 0, 0, 0, 0, 0, 0, 0, 92, 137
};



uint8_t cmd_memtest_kbd(const char* help, uint8_t arg, uint8_t menu)
{
	cls();
	while (1)
	{
		//check interrupt... plot a blob and toggle it?
		uint8_t prev = currentkey_;
		keyboardscan();

		if (prev != currentkey_) {

			set_disp(10, 10);
			printf("Current key = %02x\r\n", currentkey_);
			set_disp(10, 11);
			printf("Last key = %02x\r\n", lastkey_);
		}
	}
}

void convert2ascii(uint8_t key)
{
	char index = ((key >> 4) - 1) * 10 + (key & 0xf);
	char c = kb2ascii_[index];
	set_disp(10, 12);
	printf("Char = '%c'\r\n", c);
}

void keyboardscan()
{
	slowbusdirection(0x7f);
	slowbus0(SB_KEYBEN_N);

	for (uint8_t i = 0; i < 128; i++)
	{
		if ((i & 0xf) >= 0xa) continue; // outside keyboar matrix, don't scan

		slowbuswrite(i);
		uint8_t r = slowbusread() & 0x80;
		if (r) {
			// is pressed
			if (!(keypress_[i] & 1)) {
				// just pressed
				currentkey_ = i;
				lastkey_ = i;
				convert2ascii(i);
			}

			keypress_[i] = 0xff;
		}
		else {
			// not pressed
			keypress_[i] &= 0x80;
			if (currentkey_ == i) currentkey_ = 0xff; // unpress latest
		}
	}
	slowbus1(SB_KEYBEN_N);
}