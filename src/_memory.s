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
	.include "_zeropage.inc"
	.include "_helpers.inc"
	.include "_serial.inc"



;;=====================================
;; Memory test macros & defines
;;

;; this all needs to be 16 bit for march




.MACRO _mem_check pattern
	.local ok
	cmp pattern
	beq ok
	sta r0_
	lda pattern
	sta r1_
	_mem_error
ok:
.ENDMACRO

.MACRO _mem_check_imm pattern
	.local ok
	cmp #pattern
	beq ok
	sta r0_
	lda #pattern
	sta r1_
	_mem_error
ok:
.ENDMACRO

.MACRO _mem_error
	_jsr_zeropage ret_mem_err_, mem_error
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
	_mem_check_imm pattern
	iny
	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	iny
	bne :-
	inc p_+1
	dex
	bne :-
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
	_mem_check_imm pattern
	iny
	bne :-
	inc p_+1
	dex
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
	ldx n_
:	lda (p_),Y
	_mem_check_imm pattern
	lda #pattern^$ff
	sta (p_),Y
	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	iny
	bne :-
	inc p_+1
	dex
	bne :-

;; ↑(r1,w0);
	lda s_
	sta p_+1
	ldx n_
:	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	lda #pattern
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	dex
	bne :-

;; ↓(r0,w1);
	lda e_
	sta p_+1
	ldx n_
:	dec p_+1
:	dey
	lda (p_),Y
	_mem_check_imm pattern
	lda #pattern^$ff
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :-
	dex
	bne :--

;; ↓(r1,w0);
	lda e_
	sta p_+1
	ldx n_
:	dec p_+1
:	dey
	lda (p_),Y
	_mem_check_imm pattern ^ $ff
	lda #pattern
	sta (p_),Y
	tya		;; Z = (y==0)
	bne :-
	dex
	bne :--

;; ↕(r0)
	_march_check pattern
.ENDMACRO

;; random memory test
.MACRO _random_seed seed
	lda #<(.LOWORD(seed))
	sta seed_
	lda #>(.LOWORD(seed))
	sta seed_+1
	lda #<(.HIWORD(seed))
	sta seed_+2
	lda #>(.HIWORD(seed))
	sta seed_+3
.ENDMACRO

.MACRO _random_rng
	.local ret
	lda #<ret
	sta ret_leaf_
	lda #>ret
	sta ret_leaf_+1
	stx sx_
	jmp galois32o
ret:
	ldx sx_
.ENDMACRO

.MACRO _random_fill
	_mov_dword sseed_, seed_
	lda s_
	sta p_+1
	ldx n_
:	_random_rng
	lda seed_
	sta (p_),Y
	iny
	lda seed_+1
	sta (p_),Y
	iny
	lda seed_+2
	sta (p_),Y
	iny
	lda seed_+3
	sta (p_),Y
	iny
	bne :-
	inc p_+1
	dex
	bne :-
.ENDMACRO

.MACRO _random_check
	_mov_dword seed_, sseed_
	lda s_
	sta p_+1
	ldx n_
:	_random_rng
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
	dex
	bne :-
.ENDMACRO

;;=====================================
;; System memory test function
;; On Entry:
;;	s_  : start page of test region
;;	e_  : end page of test region
;;	k_  : <0 for infinite test
;; On Exit:
;;  r3_ : error flags

	.export mem_test
mem_test:
	ldy #0
	sty p_
	sty p_+1
	sty r3_
	
	sec
	lda e_
	sbc s_
	sta n_
	
mem_test_loop:
	;; checkerboard memory test
	_checkboard_fill $55
	_pause_ms 1
	_checkboard_check $55

	_checkboard_fill $aa
	_pause_ms 1
	_checkboard_check $aa

	;; random memory test (probes address errors)
	lda #4
	sta i_
rand_loop:
	_random_fill
	_random_check
	dec i_
	beq :+
	jmp rand_loop
:
	
	;; march c- extended
	_march_cminus_extended $55
	_march_cminus_extended $0f
	_march_cminus_extended $33
	_march_cminus_extended $00

	lda r3_
	lsr				;; test bottom bit of r3
	bcs :+			;; loop forever if memory fault detected in bottom 16KB

	bit k_			;; mem test counter, <0 means inf loops
	bmi :+	
	jmp (ret_mem_)	;; go to menu
:	jmp mem_test_loop	;; test memory again

;;=====================================
;; Memory error handler
;; 	r0   : value read
;; 	r1_  : expected pattern
;; 	p_,Y : address
;; 	X    : preserve
;; On exit
;; 	r3_	: error

mem_error:
	stx sx_
	sty sy_

	;; set screen position
	lda #13*8
	sta dst_
	lda #0
	sta dst_+1

	_ser_putc $a	;; send line feed
	
	ldx r0_			;; send read value
	_jsr_zeropage ret1_, zp_phex
	_jsr_zeropage ret_leaf_, zp_ser_phex
	
	_ser_putc '@'
	
	lda #16*8
	sta dst_	;; set screen pointer
	
	ldx p_+1		;; send address of failure HI
	_jsr_zeropage ret1_, zp_phex
	_jsr_zeropage ret_leaf_, zp_ser_phex
		
	ldx p_			;; send address of failure LO
	_jsr_zeropage ret1_, zp_phex
	_jsr_zeropage ret_leaf_, zp_ser_phex

	_ser_putc ' '
	_ser_putc '('

	lda r0_
	eor r1_
	tax

.REPEAT 8, I
	txa
	asl a
	tax					;; stash bad bits
	bcs :+
	;; not in error
	_ser_putc '0'+7-I
	bne :++				;; always true
:
	.REPEAT 8, J
		LDA font+8*('X'-' ')+J
		STA 8*(21+I)+J
	.ENDREP
	_ser_putc 'X'
:	
.ENDREP
	
	_ser_puts ") expected "
	
	lda #30*8
	sta dst_	;; set screen pointer

	ldx r1_				;; send expected value
	_jsr_zeropage ret1_, zp_phex
	_jsr_zeropage ret_leaf_, zp_ser_phex

	;; record where fault was in return flags
	lda p_+1
	rol
	rol
	rol
	and #3 		;; which 16KB chunk now in bottom 2 bits
	tax
	inx
	lda #0
	sec
:	rol			;; move bit up
	dex
	bne :-		;; set bit marks region
	
	;; merge & store in r3
	ora r3_
	sta r3_		

	;; restore registers & leave
	ldx sx_
	ldy sy_

	jmp (ret_mem_err_)


