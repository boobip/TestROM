#ifndef __HELPERS_H__
#define __HELPERS_H__

extern void far_call(void);
#define SECTION(s) __attribute__((section(s)))

#define FARCALL(fn_t, ret, pfn_hi, pfn_lo, pfn_bank, ...) {\
	ret_ = pfn_hi<<8 | pfn_lo; \
	__asm volatile(";set regs %0"::"yq"(pfn_bank));\
	ret = ((fn_t)far_call)(__VA_ARGS__); }

#define FARJMP(fn) \
	__asm volatile ( \
	"ldy #<.bank("#fn")	;; init overlay\n" \
	"	lda #.hibyte("#fn")		;; hi byte\n" \
	"	ldx #.lobyte("#fn")		;; lo byte\n" \
	"	jmp far_jump_ax" );



#endif // !__HELPERS_H__
