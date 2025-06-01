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
	.include "_noram.inc"
	.include "_nostack.inc"

;;=======================================

.PUSHSEG

.segment "VECTORS"
	vec_nmi:
		.byte <nmi_handler,>nmi_handler
	vec_rst:
		.byte <rst_handler,>rst_handler
	vec_irq:
		.byte <irq_handler,>irq_handler

.RODATA
	.export hex2ascii_lut
	hex2ascii_lut:
	.byte "0123456789ABCDEF"		



mode4_ula = $88
mode4_palette:
.byte $07,$17,$27,$37,$47,$57,$67,$77,$80,$90,$a0,$b0,$c0,$d0,$e0,$f0
mode4_crtc:
.byte $3f,$28,$31,$24,$26,$00,$20,$22,$01,$07,$67,$08
.byte >(screen_start),<(screen_start),$00,$00
screen_start=0;$5800/8
.POPSEG

;;MODE(s) 	Palette register writes (hex)
;;0, 3, 4, 6 	80 90 A0 B0 C0 D0 E0 F0 07 17 27 37 47 57 67 77
;;1, 5			A0 B0 E0 F0 84 94 C4 D4 26 36 66 76 07 17 47 57
;;2				F8 E9 DA CB BC AD 9E 8F 70 61 52 43 34 25 16 07

;; CRTC @ $c46e in MOS


;;=====================================
;; Helpers
;;

.MACRO _zp_puts str
	.local ptr,relptr
	.PUSHSEG
	.segment "STRINGS"
	ptr: .byte str,0
	.POPSEG
	relptr = <(ptr-__STRINGS_LOAD__)
	
	ldy #relptr
	_zp_call zp_puts

.ENDMACRO



.MACRO _nomem_ser_puts str
	.local ptr,relptr
	.PUSHSEG
	.segment "STRINGS"
	ptr: .byte str,0
	.POPSEG
	relptr = <(ptr-__STRINGS_LOAD__)

	ldx #relptr
	_nomem_call_sparse nomem_ser_puts, nomem_ser_puts_count, (relptr+.strlen(str))
.ENDMACRO

;.MACRO _nomem_ser_putc
;	_nomem_call nomem_ser_putc, nomem_ser_putc_count
;.ENDMACRO

.MACRO _nomem_puthex col
	ldy #(col*8)
	_nomem_call_sparse nomem_puthex, nomem_puthex_count, (col*8+16)
.ENDMACRO

.MACRO _nomem_putc col
	ldx #(col*8)
	_nomem_call_sparse nomem_putc, nomem_putc_count, (col*8+8)
.ENDMACRO

.MACRO _putc_label row, col, char
	lda font+8*(char-' '),X
	sta 8*(row*40+col),X
.ENDMACRO


;;=====================================
;; ZP memory test macros & defines
;;

.MACRO _mem_error inv
	.IFNDEF mem_error_count
		mem_error_count .set 0
	.ENDIF
	.IFNDEF mem_error_inv_count
		mem_error_inv_count .set 0
	.ENDIF
	.IFNBLANK inv
		ldy #(mem_error_inv_count*8+4)	;; return point with inverse pattern
		_nomem_call_sparse mem_error_inv, mem_error_inv_count, (mem_error_inv_count*8+4)
	.ELSE
		ldy #(mem_error_count*8)		;; return point without inverse pattern
		_nomem_call_sparse mem_error, mem_error_count, (mem_error_count*8)
	.ENDIF
.ENDMACRO

.MACRO _checkboard_fill pattern
:	lda #pattern
	sta $00,X
	inx
	lda #pattern^$ff
	sta $00,X
	inx
	bne :-
.ENDMACRO

.MACRO _checkboard_check pattern
:	lda #pattern
	eor $00,X
	beq :+
	.IF pattern=$55
		_mem_error 
	.ELSE
		_mem_error inv
	.ENDIF
:	inx
	lda #pattern^$ff
	eor $00,X
	beq :+
	.IF pattern=$55
		_mem_error inv
	.ELSE
		_mem_error
	.ENDIF
:	inx
	bne :---
.ENDMACRO



;; march C- extended
;; ↕(w0); ↑(r0,w1,r1); ↑(r1,w0);
;; ↓(r0,w1); ↓(r1,w0); ↕(r0)
.MACRO _march_cminus_extended
;; ↕(w0);
	tya				;; pattern
:	sta $00,X
	inx
	bne :-

;; ↑(r0,w1,r1);
:	tya				;; pattern
	eor $00,X
	beq :+
	_mem_error
:	tya				;; pattern
	eor #$ff		;; patterninv
	sta $00,X
	eor $00,X
	beq :+
	_mem_error inv
:	inx
	bne :---

;; ↑(r1,w0);
:	tya				;; pattern
	eor #$ff		;; patterninv
	eor $00,X
	beq :+
	_mem_error inv
:	tya				;; pattern
	sta $00,X
	inx
	bne :--

;; ↓(r0,w1);
:	dex
	tya				;; pattern
	eor $00,X
	beq :+
	_mem_error
:	tya				;; pattern
	eor #$ff		;; patterninv
	sta $00,X
	txa				;; Z = (X==0)
	bne :--

;; ↓(r1,w0);
:	dex
	tya				;; pattern
	eor #$ff		;; patterninv
	eor $00,X		;; ZP,X wraps
	beq :+
	_mem_error inv
:	tya				;; pattern
	sta $00,X		;; ZP,X wraps
	txa				;; Z = (X==0)
	bne :--

;; ↕(r0)
:	tya				;; pattern
	eor $00,X
	beq :+
	_mem_error
:	inx
	bne :--
.ENDMACRO


BACK2MOS = 1
back2moslowdst = 0

;; Dev code - disable OSRAM & return to MOS
back2mos:
	sei
	ldx #(back2moslowend-back2moslow-1)
:	lda back2moslow,X
	sta back2moslowdst,x
	dex
	bpl :-
	jmp back2moslowdst

back2moslow: ;; 13 bytes
	lda #2
	sta $ff00	;; set OSRAM ROM mode
	lda #127
	sta $fe4e	;; make MOS think cold boot
	jmp ($fffc) ;; reset
back2moslowend:
	
;;=====================================
;; initial reset handler
;; assume no memory works, no JSR
;;

	.export rst_handler
rst_handler:
	sei
	cld

;; Dev code - disable OSRAM & return to MOS on next reset
.if BACK2MOS<>0
	ldx #<back2mos
	stx $fffc
	ldx #>back2mos
	stx $fffd
.endif

;; setup video, mode 4 & leave CRTC addr on R15
	lda #mode4_ula
	sta video_ula
	ldx #15
:	lda mode4_crtc,X
	stx video_crtc_addr
	sta video_crtc_data
	lda mode4_palette,X
	sta video_ula_palette
	dex
	bpl :-

;; now in mode 4

;; reset serial chip
	lda #init_acia|3	; CR0 & CR1 1 for master reset
	sta acia

;; initialise serial 9600
	lda #init_acia
	sta acia
	lda #init_ula
	sta serialula

	_nomem_ser_puts "\r\nBooBip TestROM\r\n"

	.export init_cls
init_cls:
;; clear screen
	ldx #0
	txa
:	sta a:$0000,X
	sta a:$0100,X
	sta a:$0200,X
	sta a:$0300,X
	sta a:$0400,X
	sta a:$0500,X
	sta a:$0600,X
	sta a:$0700,X
	sta a:$0800,X
	sta a:$0900,X
	sta a:$0a00,X
	sta a:$0b00,X
	sta a:$0c00,X
	sta a:$0d00,X
	sta a:$0e00,X
	sta a:$0f00,X ;; 4k
	sta a:$1000,X
	sta a:$1100,X
	sta a:$1200,X
	sta a:$1300,X
	sta a:$1400,X
	sta a:$1500,X
	sta a:$1600,X
	sta a:$1700,X
	sta a:$1800,X
	sta a:$1900,X
	sta a:$1a00,X
	sta a:$1b00,X
	sta a:$1c00,X
	sta a:$1d00,X
	sta a:$1e00,X
	sta a:$1f00,X ;; 8k
	sta a:$2000,X
	sta a:$2100,X
	sta a:$2200,X
	sta a:$2300,X
	sta a:$2400,X
	sta a:$2500,X
	sta a:$2600,X
	sta a:$2700,X ;; 10KB - mode 4 is 10K
	inx
	bne :-

;;
	_nomem_ser_puts "Test zero page"

	;; DEBUG!!!!!!!!!!!!!!!!!!!!!
;	sed ; set memory error, loop forever
;	cli

;;jmp test_exo

;;	lda #10
;;	jsr outfn
;;
;;	ldx #$ff
;;	tsx
;;	lda #4 ;; radix/neg
;;	sta _r0
;;	_mov_dword_imm _r1, 1234
;;	lda #8 ;; n pad
;;	sta _r5
;;	lda #'0' ;; char pad
;;	sta _r6
;;	jsr hextoa
;;	
;;	
;;:jmp :-
	




;; test zero page
.RODATA
	pattern:
	.byte $55, $0F, $33, $0
	patterninv:
	.byte $AA, $F0, $CC, $FF
.CODE

memtest_zp_loop:
	ldx #0
	ldy #0

	lda #14
	sta video_crtc_addr ; leave crtc address on R14 (6 bit)

	;; checkerboard test 55, AA
zp_check:
	_checkboard_fill $55
	_pause_ms 10
	_checkboard_check $55
	
	_checkboard_fill $AA
	_pause_ms 10
	_checkboard_check $AA

	;; march test 00,0F,33,55
	ldy #0
zp_march:
	lda video_crtc_data
	and #3
	tax
	ldy pattern,X
	ldx #0

	_march_cminus_extended

	inc video_crtc_data
	lda video_crtc_data
	beq :++				;; done enough iterations?
	and #3
	bne zp_march		;; march all patterns
:	jmp zp_check		;; repeat mem test

	;; check if D flag is set, indicates memory test error
:	lda #$99
	adc #1			; add in decimal mode will set carry
	bcs :--

	;; decimal mode still clear set so RAM test completed

	;; ZP passed the test
	_zp_initstack 4 ;; don't trample mem_test args
	_zp_ser_puts ", OK\r\n" ;; We have ZP memory now

seed = $b00b19
	_mov_dword_imm seed_, seed

;; check for 16/32KB by memory alias
	lda #$80
	sta memsize_
	lsr a:memsize_ + $4000	;; check for 16KB aliasing

	;; feedback to user
s_ = _zp_stack(0)
e_ = _zp_stack(1)
k_ = _zp_stack(2)
r3_ = _zp_stack(3)
 
	lda #1
	sta s_			;; boot mem test start from stack $100
	sta k_			;; do 1 pass of memory test

	lda memsize_
	sta e_			;; boot mem test do all detected
	bmi full32KB
	
	_zp_ser_puts "16KB detected\r\nTesting &0100-&3FFF"
	lda #$16
	jmp init_memtest
full32KB:
	_zp_ser_puts "32KB detected\r\nTesting &0100-&7FFF"
	lda #$32

	.export init_memtest
init_memtest:
	_zp_initstack 4 ;; don't trample mem_test args, repeated in case we came here from menu

	ldy #8*8
	sty dst_
	ldy #0
	sty dst_+1		;; setup text destination

	;; print memory size on screen
	_zp_call zp_phex

	;; show bit positions on screen
	_zp_puts "KB mm@aaaa 76543210 ee"

	;; do memory test
	jmp mem_test
	.export mem_test_return
mem_test_return:

	;; System memory passed the test
	lda r3_
	bne rst_handler_2	;; skip printing OK if memory fault
	_zp_ser_puts ", OK\r\n" ;; TODO: reuse string from before

;; fall through to reset handler 2

;;=====================================
;; follow on reset handler
;; bottom 16KB passed memory test
;;
	.export rst_handler_2
rst_handler_2:
	sei
	cld

	ldy #<.bank(init_entry)	;; init overlay
	lda #>init_entry		;; hi byte
	ldx #<init_entry		;; lo byte
	
	jmp far_jump_ax



;;=====================================
;; Zero page memory test error handler
;; Entry:
;;	A - memory value
;;	X - return point
;;	Y - ZP address
;;	S - pattern index
;;

err_row = 5
screen_ofs = 40*8*err_row
font_zero_p = font+8*('0'-' ')
font_x_p = font+8*('X'-' ')

; got... A=read, X=addr, Y=ret
; regs... a, x, y, s

mem_error:
mem_error_inv:
	cld					;; want to be in binary mode
	txs
	ldx #15
	stx video_crtc_addr
	tsx
	stx video_crtc_data	;; store memory address in CRTC


	ldx #14
	stx video_crtc_addr

	tax					;; stash bitmask

	;; combine pattern & return address
	lda video_crtc_data ;; get pattern
	and #3
	sta video_crtc_data
	tya					;; get return address
	ora video_crtc_data
	sta video_crtc_data	;; store return address in CRTC

	txa
	tay					;; copy bitmask to Y

	;;
	;; display error bit mask - don't rely on CRTC
	_nomem_ser_puts "\r\n("	;; open bit errors

	ldx #7

biterror:
	txs					;; use S as loop counter
	tya					;; copy bitmask to A
	tsx					;; copy loop counter to X
:	lsr
	dex
	bpl :-				;; carry now holds error bit

	tsx
	txa					;; loop counter -> A
	bcc @skipdraw		;; branch taken when not in error
	
	;; bit in error, display on screen
	eor #7				;; reverse bit position
	asl
	asl
	asl
	tax					;; screen offset in X

	;; copy X to screen
	lda #$66
	sta screen_ofs+8*40+0,X
	sta screen_ofs+8*40+1,X
	sta screen_ofs+8*40+5,X
	sta screen_ofs+8*40+6,X
	lda #$3C
	sta screen_ofs+8*40+2,X
	sta screen_ofs+8*40+4,X
	lda #$18
	sta screen_ofs+8*40+3,X
	
	lda #'X'^'0'		;; EOR in '0'
@skipdraw:
	eor #'0'			;; convert loop counter to ASCII
	_tx_wait_timeout_trashX
	sta acia_d 			;; push bit posn or X for bad bit to serial
	
	;; iterate over all bits
	tsx
	dex
	bpl biterror
		
	_nomem_ser_puts ") "	;; close bit error braces

	;;
	;; serial/screen out what was read
	lda video_crtc_data
	and #7
	tax
	tya
	eor pattern,X			;; A holds byte read from memory
	tax

	_nomem_puthex 10		;; write to serial & screen
	
	_nomem_ser_puts " : "

	;;
	;; serial/screen out pattern
	lda video_crtc_data
	and #7
	tay
	ldx pattern,Y
	
	_nomem_puthex 14		;; write to serial & screen

	_nomem_ser_puts " @ 00"	;; address prefix

	;;
	;; serial/screen out address
	lda #15
	sta video_crtc_addr
	ldx video_crtc_data

	_nomem_puthex 18		;; write to serial & screen
	
	;;
	;; put labels on screen
	ldx #7
:	_putc_label err_row,18,'A'
	_putc_label err_row,10,'M'
	_putc_label err_row,14,'P'
	dex
	bpl :-
	
	;;
	;; init bit positions on screen
	ldx #8*8-1			;; 8 chars
:	txa
	eor #$38			;; want to print 7->0
	tay
	lda font_zero_p,X
	sta screen_ofs,Y
	dex
	bpl :-	

	; restore pattern to Y, mem address to X and jump point to A
	ldx video_crtc_data		;; mem address
	txs
	
	lda #14
	sta video_crtc_addr ; set crtc address to R14
	
	lda video_crtc_data ; load pattern index & return jump point
	tay

	and #3			;; mask off pattern index
	tax
	tya
	ldy pattern,X	;; restore pattern
	and #$3C		;; return jump point in A

	tsx		;; restore memtest address
	sed		;; decimal flag used to store if memory error occurred
;; return to correct point in memory test
.REPEAT mem_error_inv_count, I
	cmp #.ident(.sprintf("%s%02d_rval",.string(mem_error_inv),I))
	jeq .ident(.sprintf("%s%02d_return",.string(mem_error_inv),I))
.ENDREP
	_nomem_return_sparse mem_error, mem_error_count



;;=====================================
;; Helpers
;;

;;
;; No memory put string from X, trashes A, X
:	_tx_byte
	inx
nomem_ser_puts:
	_tx_wait_timeout
	lda __STRINGS_LOAD__,X
	bne :-				;; stop if hit null termination
	_nomem_return_sparse nomem_ser_puts, nomem_ser_puts_count, X

;;
;; No memory put char from Y, trashes A, X
;nomem_ser_putc:
;	_tx_wait_timeout
;	sty acia_d ;write data
;	_nomem_return nomem_ser_putc, nomem_ser_putc_count

;;
;; No memory put hex value to serial & screen, trashes A, X, Y, S
;; On entry value in X, posn/ret in Y
nomem_puthex:
	txs		;; preserve byte value
	
	;; putc high nibble
	txa
	lsr
	lsr
	lsr
	lsr
	tax
	lda hex2ascii_lut,X

	_tx_wait_timeout_trashX
	sta acia_d ;write data to serial port
	
	sec
	sbc #$30 ;; character zero offset '0'
	asl
	asl
	asl
	tax
:	lda font_zero_p,X
	sta screen_ofs+8*40,Y
	iny
	inx
	txa
	and #7
	bne :-
	
	;; putc low nibble
	tsx
	txa
	and #$0f
	tax
	lda hex2ascii_lut,X

	_tx_wait_timeout_trashX
	sta acia_d ;write data to serial port
	
	sec
	sbc #$30 ;; character zero offset '0'
	asl
	asl
	asl
	tax
:	lda font_zero_p,X
	sta screen_ofs+8*40,Y
	iny
	inx
	txa
	and #7
	bne :-
	
	_nomem_return_sparse nomem_puthex, nomem_puthex_count, Y

