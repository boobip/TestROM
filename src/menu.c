#include <stdint.h>
#include <stdbool.h>

#include "helpers.h"
#include "menu.h"
#include "zeropage.h"
#include "hmi.h"

__asm(";overlay=OVL0_");




#define __CODE SECTION("OVL0")
#define __DATA SECTION("OVL0")
#define __RODATA SECTION("OVL0_RODATA")

//
// emit menu enumerations
#define EMIT(m) e##m##MENU,
enum {
	MENUS
};
#undef EMIT

//
// emit menu masks
#define EMIT(m) m##MENU = (1 << e##m##MENU),
enum {
	MENUS
};
#undef EMIT





// 
// emit all menu handler function declarations
#define EMIT(func) extern uint8_t func(const char*, uint8_t, uint8_t);
MENUCOMMANDS
#undef EMIT

//
// emit function table indices
#define EMIT(func) func##_index,
enum {
	MENUCOMMANDS
};
#undef EMIT



//
// emit function table
#define EMIT(func) func,
const pfnmenuitem commands[] = {
MENUCOMMANDS
};
#undef EMIT

//
// emit function bank table
#define EMIT(func) __asm(".byte <.bank("#func")");
__asm(".segment \"RODATA\"\r\n" // RODATA will get fixed up by makedfile
"commands_bank:"); 
MENUCOMMANDS
#undef EMIT
extern uint8_t commands_bank[];

// 
// emit function pointer table
#define MENUITEM(func,...) func##_index,
const uint8_t menu_func[] = {
	MENUITEMS
};
#undef MENUITEM

static const uint8_t nitems = sizeof(menu_func) / sizeof(uint8_t);



// 
// emit menu entry table
#define MENUITEM(func, menu, arg, text) (menu),
const uint16_t menu_mask[] = {
	MENUITEMS
};
#undef MENUITEM

// 
// emit arguments table
#define MENUITEM(func, menu, arg, text) arg,
const uint8_t menu_args[] = {
	MENUITEMS
};
#undef MENUITEM

// 
// emit string table

#define MENUITEM(func, menu, arg, text) text,
const char* const menu_text[] = {
	MENUITEMS
};
#undef MENUITEM

//
// Menu state variables

struct menustate_t {
	int8_t noredraw;
	//	int8_t highlighted;
	uint8_t current;
};

//ZPBSS
struct menustate_t menustate_ = { 0 };

__CODE
static bool isincurrentmenu(uint8_t row)
{
	uint16_t mask = menu_mask[row];
	uint16_t curmask = 1 << menustate_.current;
	return !!(mask & curmask);
}

__CODE
const char* findtitle(void)
{
	for (uint8_t i = 0; i < nitems; i++)
	{
		if ((menu_func[i] == cmd_changemenu_index) && (menu_args[i] == menustate_.current))
			return menu_text[i];
	}
	return "";
}



__CODE
void RenderMenu(void)
{
	if (menustate_.noredraw) return;
	cls();

	// display title
	set_disp(menu_pos.titlex, menu_pos.titley);
	const char* title = findtitle();
	printf("\r\n** %s **\r\n", title);


	uint8_t x = menu_pos.originx;
	uint8_t y = menu_pos.originy;
	uint8_t s = menu_pos.spacing;

	uint8_t n = '0';

	for (uint8_t i = 0; i < nitems; i++)
	{
		if (!isincurrentmenu(i)) continue; // skip this row

		set_disp(x, y);
		printf("%c %s\r\n", n, menu_text[i]);

		y += s;
		++n;
	}

	menustate_.noredraw = 1;
}

__CODE
uint8_t CheckMenu(char m)
{
	uint8_t n = '0';
	for (uint8_t i = 0; i < nitems; i++)
	{
		if (!isincurrentmenu(i)) continue; // skip this row

		if (n == m) {
			//cls(); ??

			const char* label = menu_text[i];
			uint8_t arg = menu_args[i];
			uint8_t menu = menustate_.current;
			pfnmenuitem func = commands[menu_func[i]];
			if (commands_bank[menu_func[i]]==0) {

			uint8_t r = func(label, arg, menu);
			return r;
			}
		}

		++n;
	}
}



__CODE
uint8_t cmd_changemenu(const char* help, uint8_t arg, uint8_t menu)
{
	menustate_.current = arg;
	menustate_.noredraw = 0;
	//	menustate_.highlighted = 1;
}

__CODE
uint8_t cmd_memtest_zp(const char* help, uint8_t arg, uint8_t menu)
{
	set_screenstart(0);
	__asm__("sed"); // set decimal for perpetual test
	__asm__("sei"); // set interrupt disable
	__asm__("jmp init_cls"); // jump to test
	__builtin_unreachable();
}

__CODE
uint8_t cmd_memtest_sys(const char* help, uint8_t arg, uint8_t menu)
{
	set_screenstart(0);

	bool halt = (menu == eRAMHALTMENU);

	uint8_t* const s_ = &zp_stack;
	uint8_t* const e_ = &zp_stack + 1;
	uint8_t* const k_ = &zp_stack + 2;

	switch (arg)
	{
	default:
	case 0:
		*s_ = 0x1;
		*e_ = memsize_;
		break;
	case 1:
		*s_ = 0x1;
		*e_ = 0x40;
		break;
	case 2:
		*s_ = 0x40;
		*e_ = 0x80;
		break;
	case 3:
		*s_ = 0x1;
		*e_ = 0x80;
		break;
	}

	*k_ = halt ? 0xC0 : 0x80; // run forever 

	printf_ser("Testing &%04x-&%04x", (uint16_t)*s_ * 256, (uint16_t)*e_ * 256 - 1);

	uint8_t numkb = ((*e_ - *s_) / 4 > 16) ? 0x32 : 0x16;

	__asm__("sei"); // set interrupt disable
	for (char* i = (char*)0x100; i < (char*)0x2800; i++) *i = 0; // clear screen, tramples C memory
	__asm__ __volatile__("jmp init_memtest" : : "Aq" (numkb)); // jump to test
	__builtin_unreachable();
}

