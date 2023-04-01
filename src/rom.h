#ifndef __ROM_H__
#define __ROM_H__

#include <stdint.h>

typedef void(*fnhandler)();


struct THeader
{
	uint8_t  language_entry;
	fnhandler language_entry_address;
	uint8_t  service_entry;
	fnhandler service_entry_address;
	uint8_t rom_type;
	uint8_t copyright_offset;
	uint8_t versionnum;
	char title[sizeof(TITLE)];
	char version[sizeof(VERSION)];
	char copyright[sizeof(COPYRIGHT)];
	uint8_t second_processor_reloc_address[4];
};

extern struct THeader ROMHeader;





extern void OtherROMCall(char rom, void * address, char *a, char *x, char *y);

#endif // !__ROM_H__
