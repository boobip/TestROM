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
EMITZPVARS = 1
	.include "zeropage.inc"


.MACRO _pause_us n
	ldy # >((n*10)/4-1)	;4 loops ~20 cycles or 10us at 2MHz
	ldx # <((n*10)/4)
:	dex				;2
	bne :-			;3 inner loop 
	dey
	bne :-
.ENDMACRO

.MACRO _pause_ms n
	_pause_us n*1000
.ENDMACRO


;;=====================================
;; Memory test macros & defines
;;

;; this all needs to be 16 bit for march


.define mem_error_num  28

.MACRO _mem_error pattern
	.local ret
	stx sx_
	sty sy_
	sta sa_
	lda #<ret
	sta ret2_
	lda #>ret
	sta ret2_+1
	lda #pattern
	sta t0_
	jmp mem_error
ret:
.ENDMACRO

.MACRO _checkboard_fill pattern
	lda s_
	sta p_+1
	ldx n_
:	lda #pattern
	sta (p_),Y
	eor #$ff
	iny
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	dex
	bne :-
.ENDMACRO

.MACRO _checkboard_check pattern
	lda s_
	sta p_+1
	ldx n_
:	lda (p_),Y
	cmp #pattern
	beq :+
	_mem_error pattern
:	iny
	lda (p_),Y
	cmp #pattern ^ $ff
	beq :+
	_mem_error pattern^$ff
:	iny
	bne :---
	inc p_+1
	dex
	bne :---
.ENDMACRO

.MACRO _march_fill pattern
	lda s_
	sta p_+1
	ldx n_
	lda #pattern
:	sta (p_),Y
	iny
	bne :-
	inc p_+1
	dex
	bne :-	
.ENDMACRO


.MACRO _march_check pattern
	lda s_
	sta p_+1
	ldx n_
:	lda (p_),Y
	cmp #pattern
	beq :+
	_mem_error pattern
:	iny
	bne :--
	inc p_+1
	dex
	bne :--
.ENDMACRO

;; march C- extended
;; ↕(w0); ↑(r0,w1,r1); ↑(r1,w0);
;; ↓(r0,w1); ↓(r1,w0); ↕(r0)
.MACRO _march_cminus_extended pattern
	_march_fill pattern

;; ↑(r0,w1,r1);
	lda s_
	sta p_+1
	ldx n_
:	lda (p_),Y
	cmp #pattern
	beq :+
	_mem_error pattern
:	lda #pattern^$ff
	sta (p_),Y
	lda (p_),Y
	cmp #pattern^$ff
	beq :+
	_mem_error pattern^$ff
:	iny
	bne :---
	inc p_+1
	dex
	bne :---

;; ↑(r1,w0);
	lda s_
	sta p_+1
	ldx n_
:	lda (p_),Y
	cmp #pattern^$ff
	beq :+
	_mem_error pattern^$ff
:	lda #pattern
	sta (p_),Y
	iny
	bne :--
	inc p_+1
	dex
	bne :--

;; ↓(r0,w1);
	lda e_
	sta p_+1
	ldx n_
:	dec p_+1
:	dey
	lda (p_),Y
	cmp #pattern
	beq :+
	_mem_error pattern
:	lda #pattern^$ff
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :--
	dex
	bne :---

;; ↓(r1,w0);
	lda e_
	sta p_+1
	ldx n_
:	dec p_+1
:	dey
	lda (p_),Y
	cmp #pattern^$ff
	beq :+
	_mem_error pattern^$ff
:	lda #pattern
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :--
	dex
	bne :---

;; ↕(r0)
	_march_check pattern
.ENDMACRO

;;=====================================
;; 
;;

	.export mem_test_16K
mem_test_16K:

;;=====================================
;; 
;;



	.export mem_test
mem_test:
		
	
checker_fill_loop:
	ldy #0
	_checkboard_fill $55
	_pause_ms 1
	_checkboard_check $55

	_checkboard_fill $aa
	_pause_ms 1
	_checkboard_check $aa	

	_march_cminus_extended $55
	_march_cminus_extended $0f
	_march_cminus_extended $33
	_march_cminus_extended $00

	jmp checker_fill_loop

mem_error:
	jmp (ret2_)

