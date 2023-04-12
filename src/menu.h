#ifndef __MENU_H__
#define __MENU_H__

#include <stdint.h>

typedef struct {
	uint8_t originx, originy;
	uint8_t titlex, titley;
	uint8_t spacing;
} menu_pos_t;

static const menu_pos_t menu_pos = {
	10,5,
	2,2,
	2
};

typedef uint8_t(*pfnmenuitem)(const char*, uint8_t, uint8_t);

enum {ALLMENU = __UINT16_MAX__};

#define MENUS \
	EMIT(MAIN) \
	EMIT(RAM) \
	EMIT(RAMHALT) \
	EMIT(VIDEO) \
	EMIT(VIA) \
	EMIT(KEYBOARD)



#define MENUITEMS \
	MENUITEM(cmd_changemenu,  ALLMENU ^ MAINMENU, eMAINMENU, "Main Menu") \
	MENUITEM(cmd_changemenu,  MAINMENU | RAMHALTMENU, eRAMMENU, "RAM") \
	MENUITEM(cmd_changemenu,  MAINMENU, eVIDEOMENU, "Video") \
	MENUITEM(cmd_changemenu,  MAINMENU, eVIAMENU, "6522 VIAs") \
	MENUITEM(cmd_changemenu,  RAMMENU, eRAMHALTMENU, "RAM + Halt") \
	MENUITEM(cmd_memtest_zp,  RAMMENU, 0, "Zeropage") \
	MENUITEM(cmd_memtest_sys, RAMMENU | RAMHALTMENU, 0, "Main memory") \
	MENUITEM(cmd_memtest_sys, RAMMENU | RAMHALTMENU, 1, "Lower 16KB") \
	MENUITEM(cmd_memtest_sys, RAMMENU | RAMHALTMENU, 2, "Upper 16KB") \
	MENUITEM(cmd_memtest_sys, RAMMENU | RAMHALTMENU, 3, "32KB") \
	MENUITEM(cmd_changemenu,  VIDEOMENU, 0, "video test 4") \
	MENUITEM(cmd_memtest_kbd, MAINMENU, 0, "Keyboard")

#define MENUCOMMANDS \
	EMIT(cmd_changemenu) \
	EMIT(cmd_memtest_zp) \
	EMIT(cmd_memtest_sys) \
	EMIT(cmd_memtest_kbd)


extern void RenderMenu(void);
extern uint8_t CheckMenu(char m);



#endif // !__MENU_H__
