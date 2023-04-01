#include "ROM config.h"
#include "rom.h"

#include <stddef.h>

//#include "serial_debug.h"
//#include "interop.h"

// All stuff configured through "ROM config.h"

#ifdef LANGUAGE_ENTRY
extern void LANGUAGE_ENTRY(void);
#endif // LANGUAGE_ENTRY


#ifdef SERVICE_ENTRY
extern void SERVICE_ENTRY(void);
#endif // SERVICE_ENTRY



#define STR(x) #x
#define JUMP_ASM(x) __asm__ __volatile__("jmp " STR(x) "\n");

#define JUMP_ASM2(n,x) if (rega==n) __asm__ __volatile__("jmp " STR(x) "\n");


// ROM service handler
void service_handler()
{
	register uint8_t rega __asm__("a");
//	DEBUG_SER_MSGHEX("Service call ", rega);

#ifdef SERVICE_REASON_01_REQUEST_ABSOLUTE_WORKSPACE
	JUMP_ASM2(0x01, SERVICE_REASON_01_REQUEST_ABSOLUTE_WORKSPACE);
#endif

#ifdef SERVICE_REASON_02_REQUEST_PRIVATE_WORKSPACE
	JUMP_ASM2(0x02, SERVICE_REASON_02_REQUEST_PRIVATE_WORKSPACE);
#endif

#ifdef SERVICE_REASON_03_AUTOBOOT
	JUMP_ASM2(0x03, SERVICE_REASON_03_AUTOBOOT);
#endif

#ifdef SERVICE_REASON_04_UNKNOWN_COMMAND
	JUMP_ASM2(0x04, SERVICE_REASON_04_UNKNOWN_COMMAND);
#endif

#ifdef SERVICE_REASON_05_UNKNOWN_INTERRUPT
	JUMP_ASM2(0x05, SERVICE_REASON_05_UNKNOWN_COMMAND);
#endif

#ifdef SERVICE_REASON_06_BRK
	JUMP_ASM2(0x06, SERVICE_REASON_06_BRK);
#endif

#ifdef SERVICE_REASON_07_UNKNOWN_OSBYTE
	JUMP_ASM2(0x07, SERVICE_REASON_07_UNKNOWN_OSBYTE);
#endif

#ifdef SERVICE_REASON_08_UNKNOWN_OSWORD
	JUMP_ASM2(0x08, SERVICE_REASON_08_UNKNOWN_OSWORD);
#endif

#ifdef SERVICE_REASON_09_HELP
	JUMP_ASM2(0x09, SERVICE_REASON_09_HELP);
#endif

#ifdef SERVICE_REASON_0A_ABSOLUTE_WORKSPACE_CLAIM
	JUMP_ASM2(0x0a, SERVICE_REASON_0A_ABSOLUTE_WORKSPACE_CLAIM);
#endif

#ifdef SERVICE_REASON_0B_NMI_RELEASED
	JUMP_ASM2(0x0b, SERVICE_REASON_0B_NMI_RELEASED);
#endif

#ifdef SERVICE_REASON_0C_NMI_CLAIM
	JUMP_ASM2(0x0c, SERVICE_REASON_0C_NMI_CLAIM);
#endif

#ifdef SERVICE_REASON_0D_ROMFS_INITIALISE
	JUMP_ASM2(0x0d, SERVICE_REASON_0D_ROMFS_INITIALISE);
#endif

#ifdef SERVICE_REASON_0E_ROMFS_GETBYTE
	JUMP_ASM2(0x0e, SERVICE_REASON_0E_ROMFS_GETBYTE);
#endif

#ifdef SERVICE_REASON_0F_VECTORS_CLAIMED
	JUMP_ASM2(0x0f, SERVICE_REASON_0F_VECTORS_CLAIMED);
#endif

#ifdef SERVICE_REASON_10_CLOSE_SPOOL_EXEC
	JUMP_ASM2(0x10, SERVICE_REASON_10_CLOSE_SPOOL_EXEC);
#endif

#ifdef SERVICE_REASON_11_FONT_PLOSION
	JUMP_ASM2(0x11, SERVICE_REASON_11_FONT_PLOSION);
#endif

#ifdef SERVICE_REASON_12_INTIALISE_FILESYSTEM
	JUMP_ASM2(0x12, SERVICE_REASON_12_INTIALISE_FILESYSTEM);
#endif

#ifdef SERVICE_REASON_16_BEL_REQUEST
	JUMP_ASM2(0x16, SERVICE_REASON_16_BEL_REQUEST);
#endif

#ifdef SERVICE_REASON_17_SOUND_BUFFER_PURGED
	JUMP_ASM2(0x17, SERVICE_REASON_17_SOUND_BUFFER_PURGED);
#endif

#ifdef SERVICE_REASON_21_REQUEST_ABSOLUTE_WORKSPACE_HAZEL
	JUMP_ASM2(0x21, SERVICE_REASON_21_REQUEST_ABSOLUTE_WORKSPACE_HAZEL);
#endif

#ifdef SERVICE_REASON_22_REQUEST_PRIVATE_WORKSPACE_HAZEL
	JUMP_ASM2(0x22, SERVICE_REASON_22_REQUEST_PRIVATE_WORKSPACE_HAZEL);
#endif

#ifdef SERVICE_REASON_23_REPORT_TOP_ABSOLUTE_WORKSPACE_HAZEL
	JUMP_ASM2(0x23, SERVICE_REASON_23_REPORT_TOP_ABSOLUTE_WORKSPACE_HAZEL);
#endif

#ifdef SERVICE_REASON_24_PRIVATE_WORKSPACE_COUNT_HAZEL
	JUMP_ASM2(0x24, SERVICE_REASON_24_PRIVATE_WORKSPACE_COUNT_HAZEL);
#endif

#ifdef SERVICE_REASON_FE_TUBE_POST_INIT
	JUMP_ASM2(0xfe, SERVICE_REASON_FE_TUBE_POST_INIT);
#endif

#ifdef SERVICE_REASON_FF_TUBE_INIT
	JUMP_ASM2(0xff, SERVICE_REASON_FF_TUBE_INIT);
#endif

#ifdef SERVICE_DEFAULT
	JUMP_ASM(SERVICE_DEFAULT);
	__builtin_unreachable();
#endif

}


// ROM header declaration
struct THeader ROMHeader __attribute__((section("ROMHDR"))) = {
#ifdef  LANGUAGE_ENTRY
	0x4c, LANGUAGE_ENTRY, // language entry
#else
	0, 0, // no language entry
#endif //  LANGUAGE_ENTRY
#ifdef  SERVICE_ENTRY
	0x4c, SERVICE_ENTRY, // service entry
#else
	0, 0, // no service entry
#endif //  SERVICE_ENTRY
	ROM_TYPE, // rom type
	offsetof(struct THeader, copyright) - 1, // offset to copyright notice
	VERSION_NUMBER, // version
	TITLE, // ROM title
	VERSION, // ROM version string
	COPYRIGHT, // Copyright notice
	TUBE_RELOC // TUBE relocation address
};


#if 0
__attribute__((section("LOWCODE")))
__attribute__((noinline))
void OtherROMCallLow(char rom, void* address, char* a, char* x, char* y)
{
	hw_SetRomsel(rom);

	__asm__ __volatile__(
		"lda #>@return-1\n"
		"pha\n"
		"lda #<@return-1\n"
		"pha\n"
	);

	register void* addr = address;
	register uint8_t rega asm("a") = *a;
	register uint8_t regx asm("x") = *x;
	register uint8_t regy asm("y") = *y;

	__asm__ __volatile__(
		"jmp (%3)\n"
		"@return:\n"
		: "+Aq"(rega), "+xq"(regx), "+yq"(regy) : "r"(addr)
	);

	*a = rega;
	*x = regx;
	*y = regy;

	os_SelectRomFromCopy();
}

void OtherROMCall(char rom, void* address, char* a, char* x, char* y)
{
	__asm__ __volatile__(
		//".import __LOWCODE_SIZE__\n"
		//".import __LOWCODE_RUN__\n"
		//".import __LOWCODE_LOAD__\n"
		"ldx #<__LOWCODE_SIZE__\n"
		"@lowcodecopy:\n"
		"lda __LOWCODE_LOAD__-1,x\n"
		"sta __LOWCODE_RUN__-1,x\n"
		"dex\n"
		"bne @lowcodecopy\n"
		"php\n"
		"sei\n"
		: : : "x", "a", "cc"
	);

	OtherROMCallLow(rom, address, a, x, y);

	__asm__ __volatile__(
		"plp\n"
		: : : "cc"
	);
}

#endif // 0
