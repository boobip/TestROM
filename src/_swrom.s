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
	.segment "CODEHW"

	.feature string_escapes
	
	.export svc_help

; save zero page registers area to stack
.MACRO _save_zp
	ldx #$39
:	lda $50,x
	sta $100,x
	dex
	bpl :-
.ENDMACRO

; restore zero page registers area from stack
.MACRO _restore_zp
	ldy #$39
:	lda $100,y
	sta $50,y
	dey
	bpl :-
.ENDMACRO

svc_help:
	tya
	pha
	_save_zp
	lda #<$cff
	sta _sp0
	lda #>$cff
	sta _sp1
	
	sty _r0			;; first argument for C function
	jsr swr_help
	
	_restore_zp
	pla
	tay
	lda #9
	ldx $f4
	rts

