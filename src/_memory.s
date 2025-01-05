	.feature at_in_identifiers
	.feature dollar_in_identifiers
	.autoimport +
	.p02
	.importzp _sp0, _sp1, _fp0, _fp1
	.importzp _r0, _r1, _r2, _r3, _r4, _r5, _r6, _r7
	.importzp _s0, _s1, _s2, _s3, _s4, _s5, _s6, _s7
	.importzp _e0, _e1, _e2, _e3, _e4, _e5, _e6, _e7
	.importzp _e8, _e9, _e10, _e11, _e12, _e13, _e14, _e15
	.importzp _e16, _e17, _e18, _e19, _e20, _e21, _e22, _e23
	.importzp _e24, _e25, _e26, _e27, _e28, _e29, _e30, _e31
	.importzp _tmp0, _tmp1
	.importzp _sa, _sx, _sy
	.segment "CODE"

	.feature string_escapes
EMITZPVARS .set 1
	.include "_zeropage.inc"
	.include "_helpers.inc"
	.include "_serial.inc"
	.include "_hardware.inc"
	.include "_nostack.inc"



	.MACPACK longbranch
	.feature org_per_seg
	



;;=====================================
;; Memory test macros & defines
;;

;; this all needs to be 16 bit for march




.MACRO _mem_check pattern
	.local ok
	cmp pattern
	beq ok
	sty p_
	ldy pattern
	_zp_call mem_error
ok:
.ENDMACRO

.MACRO _mem_check_imm pattern
	.local ok
	cmp #pattern
	beq ok
	sty p_
	ldy #pattern
	_zp_call mem_error
ok:
.ENDMACRO

.MACRO _checkboard_fill pattern
	lda s_
	sta p_+1
:	lda #pattern
	sta (p_),Y
	eor #$ff
	iny
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-
.ENDMACRO

.MACRO _checkboard_check pattern
	lda s_
	sta p_+1
:	lda (p_),Y
	_mem_check_imm pattern
	iny
	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-
.ENDMACRO

.MACRO _march_fill pattern
	lda s_
	sta p_+1
:	lda #pattern
:	sta (p_),Y
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :--
.ENDMACRO


.MACRO _march_check pattern
	lda s_
	sta p_+1
:	lda (p_),Y
	_mem_check_imm pattern
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-
.ENDMACRO

;; march C- extended
;; ↕(w0); ↑(r0,w1,r1); ↑(r1,w0);
;; ↓(r0,w1); ↓(r1,w0); ↕(r0)
.MACRO _march_cminus_extended pattern
	_march_fill pattern

;; ↑(r0,w1,r1);
	lda s_
	sta p_+1
:	lda (p_),Y
	_mem_check_imm pattern
	lda #pattern^$ff
	sta (p_),Y
	lda (p_),Y
	_mem_check_imm (pattern ^ $ff)
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-

;; ↑(r1,w0);
	lda s_
	sta p_+1
:	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	lda #pattern
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-

;; ↓(r0,w1);
	lda e_
	sta p_+1
:	dec p_+1
:	dey
	lda (p_),Y
	_mem_check_imm pattern
	lda #pattern^$ff
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :-
	lda p_+1
	cmp s_
	bne :--

;; ↓(r1,w0);
	lda e_
	sta p_+1
:	dec p_+1
:	dey
	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	lda #pattern
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :-
	lda p_+1
	cmp s_
	bne :--

;; ↕(r0)
	_march_check pattern
.ENDMACRO



;
; 6502 LFSR PRNG - 32-bit
; Brad Smith, 2019
; http://rainwarrior.ca
;

; A 32-bit Galois LFSR

; Possible feedback values that generate a full 4294967295 step sequence:
; $AF = %10101111
; $C5 = %11000101
; $F5 = %11110101

; $C5 is chosen


; overlapped
; 83 cycles
; 44 bytes
.MACRO _random_rng
	; rotate the middle bytes left
	ldx seed_+2 ; will move to seed_+3 at the end
	lda seed_+1
	sta seed_+2
	; compute seed_+1 ($C5>>1 = %1100010)
	lda seed_+3 ; original high byte
	lsr
	sta seed_+1 ; reverse: 100011
	lsr
	lsr
	lsr
	lsr
	eor seed_+1
	lsr
	eor seed_+1
	eor seed_+0 ; combine with original low byte
	sta seed_+1
	; compute seed_+0 ($C5 = %11000101)
	lda seed_+3 ; original high byte
	asl
	eor seed_+3
	asl
	asl
	asl
	asl
	eor seed_+3
	asl
	asl
	eor seed_+3
	stx seed_+3 ; finish rotating byte 2 into 3
	sta seed_+0
.ENDMACRO

;; random memory test

.MACRO _random_fill
	_mov_dword sseed_, seed_
	lda s_
	sta p_+1
:	_random_rng		;; on exit A = seed_+0, X = seed_+3
	sta (p_),Y
	iny
	lda seed_+1
	sta (p_),Y
	iny
	lda seed_+2
	sta (p_),Y
	iny
	txa				;;	lda seed_+3	
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-
.ENDMACRO

.MACRO _random_check
	_mov_dword seed_, sseed_
	lda s_
	sta p_+1
:	_random_rng		;; trashes X
	lda (p_),Y
	_mem_check seed_
	iny
	lda (p_),Y
	_mem_check seed_+1
	iny
	lda (p_),Y
	_mem_check seed_+2
	iny
	lda (p_),Y
	_mem_check seed_+3
	iny
	bne :-
	inc p_+1
	lda p_+1
	cmp e_
	bne :-
.ENDMACRO

;;=====================================
;; System memory test function
;; On Entry:
;;	s_  : start page of test region
;;	e_  : end page of test region
;;	k_  : <0 for infinite test
;; On Exit:
;;  A   : error flags

EMITZPVARS .set 2
.ZEROPAGE
.org zp_stack
	;; parameters
	_zp_byte s_
	_zp_byte e_
	_zp_byte k_
	;; scratch vars
	_zp_byte r3_
	_zp_word p_
	_zp_byte j_
	_zp_dword sseed_
scratch_end:
.CODE


;; mem_test - always root, can access args by absolute address

	.export mem_test
.proc mem_test
	_zp_initstack (scratch_end-zp_stack)
	ldy #0
	sty p_
	sty p_+1
	sty r3_

mem_test_loop:
	;; checkerboard memory test
	_checkboard_fill $55
	_pause_ms 10			;; trashes X!
	_checkboard_check $55

	_checkboard_fill $aa
	_pause_ms 10			;; trashes X!
	_checkboard_check $aa
;jmp skip4testing ;; HACK!

	;; random memory test (probes address errors)
	lda #4
	sta j_
rand_loop:
	_random_fill
	_random_check
	dec j_
	beq :+
	jmp rand_loop
:
skip4testing: ;; HACK!
	;; march c- extended
	_march_cminus_extended $55	;; could save ~700 bytes by putting this in a loop
	_march_cminus_extended $33
	_march_cminus_extended $0f
	_march_cminus_extended $00

	lda r3_
	lsr				;; test bottom bit of r3
	bcs :+			;; loop forever if memory fault detected in bottom 16KB

	bit k_			;; mem test counter, <0 means inf loops
	bmi :+
	
	lda r3_
	jmp mem_test_return	;; go to menu
:	jmp mem_test_loop	;; test memory again
.endproc

;;=====================================
;; Memory error handler
;;  p_   : address
;;  A    : value read
;;  Y    : expected pattern
;; On exit
;; 	r3_	: error

_zp_func_prologue mem_error, {read pat mask}

	sta read,X
	sty pat,X

	;; set screen position
	lda #13*8
	sta dst_
	lda #0
	sta dst_+1

	_zp_ser_puts "\r\n" ;; send CRLF

	lda read,X			;; send read value
	_zp_call zp_phex
	_zp_call zp_ser_phex


	lda #'@'
	_zp_call zp_ser_putc

	lda #16*8
	sta dst_			;; set screen pointer

	lda p_+1			;; send address of failure HI
	_zp_call zp_phex
	_zp_call zp_ser_phex

	lda p_				;; send address of failure LO
	_zp_call zp_phex
	_zp_call zp_ser_phex

	_zp_ser_puts " ("

	lda read,X
	eor pat,X
	sta mask,X

	ldy #'7'
	sec
	rol mask,X
loop_biterr:
	tya
	bcc :+
	;; in error

	;; generate char posn on screen
	and #7
	eor #7
	asl
	asl
	asl
	adc #21*8			;; offset char posn 21
	sta dst_			;; save screen posn in dst_ 

	lda #'X'
	_zp_call zp_putc

:	_zp_call zp_ser_putc

	dey
	asl mask,X
	bne loop_biterr

	_zp_ser_puts ") expected " 

	lda #30*8
	sta dst_	;; set screen pointer

	lda pat,X				;; send expected value
	_zp_call zp_phex
	_zp_call zp_ser_phex

	;; record where fault was in return flags
	lda p_+1
	rol
	rol
	rol
	and #3 		;; which 16KB chunk now in bottom 2 bits
	tay
	iny
	lda #0
	sec
:	rol			;; move bit up
	dey
	bne :-		;; set bit marks region

	;; merge & store in r3
	ora r3_
	sta r3_

:	bit k_			;; mem test counter
	bvs :-			;; bit 6 : HALT on first error

	;; restore address & leave
	ldy p_
	lda #0
	sta p_

	_zp_func_epilogue


