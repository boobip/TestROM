#ifndef __BBC_B_MACHINE_H__
#define __BBC_B_MACHINE_H__

#include <stdint.h>

// memory map
volatile static uint8_t*const _hw_shiela_romsel = (uint8_t*)0xfe30;



// helper functions
inline static void hw_SetRomsel(char bank) { *_hw_shiela_romsel = bank; }


#endif // !__BBC_B_MACHINE_H__
