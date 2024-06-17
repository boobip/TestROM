	.include "_zeropage.inc"

	.feature org_per_seg

	decrunch_table = $100

	.export get_crunched_byte: absolute
	.import decrunch
	.importzp zp_stack


.enum OVERLAYS
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

	;; patch in data address
	lda ovl_tbl_lo,Y
	sta _byte_lo
	lda ovl_tbl_hi,Y
	sta _byte_hi

	;; call exomizer
	jmp decrunch ;; tail call
.endproc


	

;; Declare segment for linker
.segment "OVERLAYS"


;; TESTING STUFF vvv

.export _bank1
_bank1=.bank(_ovl1_tbl)
.export _bank2
_bank2=.bank(decrunch_ovl)


.segment "OVL1"
	.export _ovl1_tbl
	_ovl1_tbl:
	.byte 4
.segment "OVL2"
	.export _ovl2_tbl
	_ovl2_tbl:
	.byte 9

