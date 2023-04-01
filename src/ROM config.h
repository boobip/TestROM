#ifndef __ROM_CONFIGURATION_H__
#define __ROM_CONFIGURATION_H__

// set up ROM values
#define VERSION_NUMBER 1U
#define TITLE "BooBip Test ROM"
#define VERSION "0.01 " __DATE__ "/" __TIME__
#define COPYRIGHT "(C) BooBip.com 2023"

__attribute__((section("CODEHW")))
 void service_handler(void);

//#define LANGUAGE_ENTRY func
#define SERVICE_ENTRY service_handler
#define ROM_TYPE 0x82
#define TUBE_RELOC "ROFF"

// BBC B service calls. Uncomment required ones and set to handler function name
// https://beebwiki.mdfs.net/Service_calls

//#define SERVICE_REASON_01_REQUEST_ABSOLUTE_WORKSPACE 			svc_absclaim1
//#define SERVICE_REASON_02_REQUEST_PRIVATE_WORKSPACE 			func
//#define SERVICE_REASON_03_AUTOBOOT 							func
//#define SERVICE_REASON_04_UNKNOWN_COMMAND						svc_command
//#define SERVICE_REASON_05_UNKNOWN_INTERRUPT 					func
//#define SERVICE_REASON_06_BRK 									svc_brk
//#define SERVICE_REASON_07_UNKNOWN_OSBYTE 						func
//#define SERVICE_REASON_08_UNKNOWN_OSWORD 						func
//#define SERVICE_REASON_09_HELP									svc_help
//#define SERVICE_REASON_0A_ABSOLUTE_WORKSPACE_CLAIM 			func
//#define SERVICE_REASON_0B_NMI_RELEASED 						func
//#define SERVICE_REASON_0C_NMI_CLAIM 							func
//#define SERVICE_REASON_0D_ROMFS_INITIALISE 					func
//#define SERVICE_REASON_0E_ROMFS_GETBYTE 						func
//#define SERVICE_REASON_0F_VECTORS_CLAIMED 						svc_vectors
//#define SERVICE_REASON_10_CLOSE_SPOOL_EXEC 					func
//#define SERVICE_REASON_11_FONT_PLOSION 						func
//#define SERVICE_REASON_12_INTIALISE_FILESYSTEM 				func
//#define SERVICE_REASON_16_BEL_REQUEST							func
//#define SERVICE_REASON_17_SOUND_BUFFER_PURGED					func
//#define SERVICE_REASON_21_REQUEST_ABSOLUTE_WORKSPACE_HAZEL	func
//#define SERVICE_REASON_22_REQUEST_PRIVATE_WORKSPACE_HAZEL		func
//#define SERVICE_REASON_23_REPORT_TOP_ABSOLUTE_WORKSPACE_HAZEL	func   
//#define SERVICE_REASON_24_PRIVATE_WORKSPACE_COUNT_HAZEL		func
//#define SERVICE_REASON_FE_TUBE_POST_INIT 						func
//#define SERVICE_REASON_FF_TUBE_INIT 							func
//#define SERVICE_DEFAULT			 							func

//#include "rom.h"

#endif // !__ROM_CONFIGURATION_H__

