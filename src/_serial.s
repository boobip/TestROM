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
	.include "_serial.inc"
	.include "_hardware.inc"
	.include "_nostack.inc"



;;=====================================
;; Put string to serial using zeropage return mechanism
;; On Entry:
;;  Y    : string offset
;;  dst_ : destination pointer
;; On Exit:
;;  dst_ += strlen*8
;; Clobbers:
;;  A, Y

_zp_func_prologue zp_ser_puts
	
:	lda __STRINGS_LOAD__,Y
	beq done
	_zp_call zp_ser_putc
	iny
	bne :-		;; always branch, looking for null termination
done:

_zp_func_epilogue

;;=====================================
;; Put character to serial using zeropage return mechanism
;; On Entry:
;;  A    : character to print
;; On Exit:
;;  
;; Clobbers:
;;  A

_zp_func_prologue zp_ser_putc

	sty sy_
	_tx_wait_timeout_y	;; trashes Y
	lda sa_	;; call saved a in sa_
	_tx_byte
	ldy sy_
	
_zp_func_epilogue

;;=====================================
;; Put hex to serial using zeropage return mechanism 
;; On Entry:
;;  A    : number to print
;; Clobbers:
;;  Y

_zp_func_prologue zp_ser_phex, {n}

	sta n,X				;; save number in n
	_hex2ascii_lut_hi Y
	_zp_call zp_ser_putc
	lda n,X
	_hex2ascii_lut_lo Y
	_zp_call zp_ser_putc
	lda n,X	
	
_zp_func_epilogue
