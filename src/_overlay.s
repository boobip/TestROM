	.include "_zeropage.inc"

	.feature org_per_seg

	decrunch_table = $100

	.export get_crunched_byte: absolute
	.import decrunch
	.importzp zp_stack


.enum OVERLAYS
	init
	menu
	helloworld
	noverlays
.endenum

.export numoverlays
numoverlays = OVERLAYS::noverlays


;;
;; Overlays table
.segment "OVL_TBL"
	.export ovl_tbl_lo, ovl_tbl_hi
ovl_tbl_lo:
	.res numoverlays
ovl_tbl_hi:
	.res numoverlays


.CODE

get_crunched_byte = zp_stack
_byte_lo = get_crunched_byte+1
_byte_hi =_byte_lo + 1
get_crunched_byte_start:
	lda $ffff			;; needs to be set correctly before calling decrunch
	inc _byte_lo
	bne _byte_skip_hi
	inc _byte_hi
_byte_skip_hi:
	rts					
get_crunched_byte_end:


;;
;; Decrunch an overlay
;; On entry OVL number in Y

	.export decrunch_ovl
.proc decrunch_ovl

	;; copy get_crunched_byte routine to RAM
	ldx#get_crunched_byte_end-get_crunched_byte_start-1
:	lda get_crunched_byte_start,X
	sta get_crunched_byte,X
	dex
	bpl :-

	sty current_bank_
	
	;; patch in data address
	lda ovl_tbl_hi,Y
	sta _byte_hi
	lda ovl_tbl_lo,Y
	sta _byte_lo

	;; call exomizer
	jmp decrunch ;; tail call
.endproc

;; far_call
;; on entry new bank in Y, func in ret_
	.export far_call
.proc far_call
	
	lda current_bank_
	pha

	cpy current_bank_
	beq :+			;; if same bank then skip overlay expand
	tya
	bmi :+			;; if ROM (bank FF) skip overlay expand
	
	jsr decrunch_ovl
	
:	jsr jmp_ret_	;; do function call
	
	pla				;; pop previous bank
	cmp current_bank_
	beq	:+			;; if same bank then skip overlay expand
	tay
	bmi :+			;; if ROM (bank FF) skip overlay expand
	
	jmp decrunch_ovl ;; tail call
	
:	rts	
.endproc


;; far_jump_ax
;; on entry new bank in Y, func AX
	.export far_jump_ax
far_jump_ax:
	sta ret_+1
	stx ret_

;; far_jump
;; on entry new bank in Y, func in ret_
	.export far_jump
far_jump:
	ldx #$ff
	txs					;; reset stack
	jsr decrunch_ovl
jmp_ret_:
	jmp (ret_)
	

;; Declare segment for linker
.segment "OVERLAYS"


;; TESTING STUFF vvv

.segment "OVL2"
	.export _ovl2_tbl
	_ovl2_tbl:
	.byte 9

