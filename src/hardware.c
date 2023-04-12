#include "hardware.h"

void slowbus_sn76489_write(uint8_t data)
{
	slowbusdirection(0xff);
	slowbuswrite(data);
	slowbus0(SB_SN76489);
	NOPDELAY(8);
	slowbus1(SB_SN76489);
}

