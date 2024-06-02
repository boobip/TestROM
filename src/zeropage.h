#ifndef __ZEROPAGE_H__
#define __ZEROPAGE_H__

//#define IMPORTZP(type, name) __asm__(".importzp "#name); volatile extern type name;
#define IMPORTZP(type, name) __asm__(".importzp "#name); extern type name;

#define ZPBSS __attribute__((section("ZPBSS")))

#include <stdint.h>

IMPORTZP(uint8_t, _myzp)
IMPORTZP(uint8_t, _myzp2)



struct S {
	int a;
	int b;
};
IMPORTZP(struct S, _myzpstruct)



#define _zp_byte(name)  IMPORTZP(uint8_t, name)
#define _zp_word(name)  IMPORTZP(uint16_t, name)
#define _zp_dword(name) IMPORTZP(uint32_t, name)

_zp_word(p_)
_zp_byte(s_)
_zp_byte(e_)
_zp_byte(n_)
_zp_byte(i_)
_zp_byte(j_)
_zp_byte(k_)
_zp_word(ret1_)
_zp_word(ret_mem_err_)
_zp_word(ret_mem_)
_zp_word(ret_leaf_)
_zp_byte(sa_)
_zp_byte(sx_)
_zp_byte(sy_)
_zp_byte(r0_)
_zp_byte(r1_)
_zp_byte(r2_)
_zp_byte(r3_)
_zp_dword(seed_)
_zp_dword(sseed_)
_zp_word(src_)
_zp_word(dst_)
_zp_byte(memsize_)

_zp_byte(zp_stack)


#undef IMPORTZP

#endif