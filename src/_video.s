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
	.include "_zeropage.inc"
	.include "_helpers.inc"

font_base = $f800

;;=====================================
;; Put character to screen using zeropage return mechanism
;; On Entry:
;;  r2_  : character to print
;;  dst_ : destination pointer
;; On Exit:
;;  dst_ += 8
;; Clobbers:
;;  A, Y
	.export zp_putc
zp_putc:
	lda r2_
	and #$7f		;; defensive
	ldy #>(font_base>>2)
	sty src_+1
	asl 
	asl 
	rol src_+1
	asl 
	rol src_+1		;; multiply character by 8
	sta src_		;; (src) contains pointer to character in ROM
	ldy #0
:	lda (src_),Y
	sta (dst_),Y
	iny
	cpy #8			;; 8 rows of char
	bne :-
	clc
	lda dst_
	adc #8
	sta dst_
	bcc :+
	inc dst_+1	
:	jmp (ret_leaf_)

;;=====================================
;; Put hex to screen using zeropage return mechanism 
;; On Entry:
;;  X    : number to print
;;  dst_ : destination pointer
;; On Exit:
;;  dst_ += 8
;; Clobbers:
;;  A, Y
	.export zp_phex
zp_phex:
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
	sta r2_
	_jsr_zeropage ret_leaf_, zp_putc 
	txa			; restore value
	and #$0F
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
	sta r2_
	_jsr_zeropage ret_leaf_, zp_putc
	jmp (ret1_)
