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
;;1, 5 	A0 B0 E0 F0 84 94 C4 D4 26 36 66 76 07 17 47 57
;;2 	F8 E9 DA CB BC AD 9E 8F 70 61 52 43 34 25 16 07

;; CRTC @ $c46e in MOS





;;=====================================
;; Helpers
;;

back2moslow: ;; 14 bytes
	sei
	lda #2
	sta $ff00
	lda #127
	sta $fe4e
	jmp ($fffc)
back2moslowend:

.MACRO _back2mos dst
	ldx #(back2moslowend-back2moslow-1)
:	lda back2moslow,X
	sta dst,x
	dex
	bpl :-
	ldx #<dst
	stx $fffc
	ldx #>dst
	stx $fffd
.ENDMACRO

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

.MACRO _nomem_ser_putc
	_nomem_call nomem_ser_putc, nomem_ser_putc_count
.ENDMACRO

.MACRO _nomem_putc col
	ldx #(col*8)
	_nomem_call_sparse nomem_putc, nomem_putc_count, (col*8+8)
.ENDMACRO

.MACRO _nomem_putc_label col, char
	ldx #(col*8)
	ldy #(char-'@')*8
	_nomem_call_sparse nomem_putc_lab, nomem_putc_lab_count, (col*8+8)
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
	txs								;; stash pattern in S
	.IFNBLANK inv
		ldx #(mem_error_inv_count*8+4)	;; return point with inverse pattern
		_nomem_call_sparse mem_error_inv, mem_error_inv_count, (mem_error_inv_count*8+4)
	.ELSE
		ldx #(mem_error_count*8)	;; return point without inverse pattern
		_nomem_call_sparse mem_error, mem_error_count, (mem_error_count*8)
	.ENDIF
.ENDMACRO

.MACRO _checkboard_fill pattern
	lda #pattern
:	sta $00,Y
	eor #$ff
	iny
	bne :-
.ENDMACRO

.MACRO _checkboard_check pattern
:	lda $00,Y
	cmp #pattern
	beq :+
	.IF pattern=$55
		_mem_error 
	.ELSE
		_mem_error inv
	.ENDIF
:	iny
	lda $00,Y
	cmp #pattern^$ff
	beq :+
	.IF pattern=$55
		_mem_error inv
	.ELSE
		_mem_error
	.ENDIF
:	iny
	bne :---
.ENDMACRO



;; march C- extended
;; ↕(w0); ↑(r0,w1,r1); ↑(r1,w0);
;; ↓(r0,w1); ↓(r1,w0); ↕(r0)
.MACRO _march_cminus_extended
;; ↕(w0);
	lda pattern,X
:	sta $00,Y
	iny
	bne :-

;; ↑(r0,w1,r1);
:	lda $00,Y
	cmp pattern,X
	beq :+
	_mem_error
:	lda patterninv,X
	sta $00,Y
	lda $00,Y
	cmp patterninv,X
	beq :+
	_mem_error inv
:	iny
	bne :---

;; ↑(r1,w0);
:	lda $00,Y
	cmp patterninv,X
	beq :+
	_mem_error inv
:	lda pattern,X
	sta $00,Y
	iny
	bne :--

;; ↓(r0,w1);
:	dey
	lda $00,Y
	cmp pattern,X
	beq :+
	_mem_error
:	lda patterninv,X
	sta $00,Y
	tya		;; Z = (y==0)
	bne :--

;; ↓(r1,w0);
:	dey
	lda $00,Y
	cmp patterninv,X
	beq :+
	_mem_error inv
:	lda pattern,X
	sta $00,Y
	tya		;; Z = (y==0)
	bne :--

;; ↕(r0)
:	lda $00,Y
	cmp pattern,X
	beq :+
	_mem_error
:	iny
	bne :--
.ENDMACRO

;;=====================================
;; initial reset handler
;; assume no memory works, no JSR
;;

.MACRO _withlabel
: NOP
.ENDMacro

	.export rst_handler
rst_handler:
	sei
	cld

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
	_back2mos $200
;	sed ; set memory error, loop forever

;; test zero page
.RODATA
	pattern:
	.byte $55, $0F, $33, $0
	patterninv:
	.byte $AA, $F0, $CC, $FF
.CODE

memtest_zp_loop:
	lda #15
	sta video_crtc_addr ; leave crtc address on R15 (8 bit)

	;; checkerboard test 55, AA
	ldx #0
	ldy #0
zp_check:
	_checkboard_fill $55
	_pause_ms 10
	_checkboard_check $55
	
	_checkboard_fill $AA
	_pause_ms 10
	_checkboard_check $AA

	;; march test 00,0F,33,55
	ldx #0
	ldy #0
zp_march:
	_march_cminus_extended

	inx
	cpx #4
	beq :+
	jmp zp_march
:

	;; check if D flag is set
	lda #$99
	adc #1			; add in decimal mode will set carry
	bcc :+
	jmp memtest_zp_loop ;; seen an error... spin forever
:	;; decimal mode still clear set so RAM test completed

	;; DEBUG!!!!!!!!!!!!!!!!!!!!!
	_back2mos $30 ;; tramples X


	;; ZP passed the test
	_zp_initstack 4 ;; don't trample mem_test args
	_zp_ser_puts ", OK\r\n" ;; We have ZP memory now

seed = $b00b19
	_mov_dword_imm seed_, seed

;; check for 16/32KB by memory alias
	lda #$80
	sta memsize_
	lsr
	sta a:memsize_ + $4000

	;; feedback to user
s_ = _zp_stack(0)
e_ = _zp_stack(1)
k_ = _zp_stack(2)
r3_ = _zp_stack(3)
 
	lda #2
	sta s_			;; boot mem test start from stack $100
	sta k_			;; do 1 pass of memory test

	lda memsize_
	sta e_			;; boot mem test do all detected
	bmi full32KB
	
;	_zp_ser_puts "16KB detected\r\nTesting &0100-&3FFF"
	lda #$16
	jmp init_memtest
full32KB:
;	_zp_ser_puts "32KB detected\r\nTesting &0100-&7FFF"
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

;	jmp rst_handler_2
;; fall through to reset handler 2

;;=====================================
;; follow on reset handler
;; ZP & stack tested OK
;;
	.export rst_handler_2
rst_handler_2:
	sei
	cld
	ldx #$ff
	txs		; intialise stack pointer


	lda #<__STACKTOP__
	sta _sp0			;; intialise C soft stack
	lda #>__STACKTOP__
	sta _sp1

;; TODO: move BSS, ZPBSS, DATA copies etc to ASM to save ROM space. 

;	// cleanup Zero Page
;	lda #0
;	ldx #$50
;:	sta &00,X
;	inx
;	bne :-

;:	jmp :- ;; spin wait for RESET

	jmp rst_handler_3 ;; go to C code


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

; got... read, addr, pat
; regs... a, x, y, s

mem_error:
mem_error_inv:
	cld ;; decimal flag messes with serial timeout
	sty video_crtc_data ;; stash mem address in crtc

	ldy #14
	sty video_crtc_addr

	stx video_crtc_data ;; stash return point in crtc

	;; add index to stashed return point to combine
	tsx
:	dex
	bmi :+
	inc video_crtc_data
	bne :-
:
	iny
	sty video_crtc_addr	;; back to crtc R15

	;; A = read value
	tax
	txs ;; stash in S

	;;
	;; serial/screen out what was read
	_hex2ascii_lut_hi Y		;; high char->A
	tay
	_nomem_ser_puts "\r\n"
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 14

	tsx
	txa
	_hex2ascii_lut_lo Y		;; low char->A
	tay
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 15

	;;
	;; serial/screen out address
	lda video_crtc_data
	_hex2ascii_lut_hi Y		;; high char->A
	tay
	_nomem_ser_puts " @ 00"	;; address prefix
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 10

	lda video_crtc_data
	_hex2ascii_lut_lo Y		;; low char->A
	tay
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 11

	_nomem_ser_puts " ("	;; open bit errors

	;;
	;; fetch pattern index from CRTC & lookup pattern
	ldy #14
	sty video_crtc_addr
	lda video_crtc_data

	and #7
	tay

	;;
	;; display error bit mask
	tsx					;; restore read value
	txa
	eor pattern,y		;; make bitmask for bad bits
	
	ldx #'7'
	txs					;; stash bit number in S

	sec
	rol a				;; get 1st bit & rol in a 1 for loop counting
biterror:
	tay 				;; stash bitmask in Y
	tsx
	txa					;; bit posn char -> A
	bcc @next			;; branch taken when not in error
	
	;; bit in error, display on screen
	eor #$ff
	adc #'7'			;; carry set here
	asl
	asl
	asl
	tax					;; screen offset in X

	;; hard coded X
	lda #$66
	sta screen_ofs+8*40+0,X
	sta screen_ofs+8*40+1,X
	sta screen_ofs+8*40+5,X
	sta screen_ofs+8*40+6,X
	lda #$3c
	sta screen_ofs+8*40+2,X
	sta screen_ofs+8*40+4,X
	lda #$18
	sta screen_ofs+8*40+3,X
	lda #0
	sta screen_ofs+8*40+7,X

	ldx #'X'
@next:
	_tx_wait_timeout
	stx acia_d 			;; push bit posn or X for bad bit to serial
	pha					;; decrement S
	tya
	asl a				;; shift right, once zero R13 zero again - OK
	bne biterror
	
	_nomem_ser_puts ") pat: "	;; close bit error braces
	
	;;
	;; fetch pattern index from CRTC & lookup pattern
	lda video_crtc_data

	and #7
	tay
	ldx pattern,y
	txs
	
	;;
	;; serial/screen out pattern
	txa
	_hex2ascii_lut_hi Y		;; high char->A
	tay
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 18

	tsx
	txa
	_hex2ascii_lut_lo Y		;; low char->A
	tay
	_nomem_ser_putc

	;; write to screen
	_nomem_putc 19

	_nomem_putc_label 10,'A'
	_nomem_putc_label 14,'M'
	_nomem_putc_label 18,'P'
	
	;;
	;; init bit positions on screen
	
	ldx #7*8			;; start at font char '7'
	txs
	ldy #0

:	tsx
:	lda font_zero_p,X
	sta screen_ofs,Y
	pha					;; decrement S
	inx
	iny
	tya
	and #7				;; finished this char?
	bne :-
	cpy #64				;; finshed 8 chars?
	bne :--
	

	; restore pattern index to X, mem address to Y and jump point to A
	lda video_crtc_data ; load pattern index & return jump point

	tay
	and #3			;; mask off pattern index
	tax
	tya		
	and #$3C		;; return jump point in A

	ldy #15
	sty video_crtc_addr ; set crtc address to R15
	ldy video_crtc_data ; restore memtest address
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
	_nomem_return_sparse_x nomem_ser_puts, nomem_ser_puts_count

;;
;; No memory put char from Y, trashes A, X
nomem_ser_putc:
	_tx_wait_timeout
	sty acia_d ;write data
	_nomem_return nomem_ser_putc, nomem_ser_putc_count

;;
;; No memory put char to screen, trashes A, X, Y
nomem_putc:
	tya
	sec
	sbc #$30 ;; character zero offset
	asl
	asl
	asl
	tay
:	lda font_zero_p,Y
	sta screen_ofs+8*40,X
	iny
	inx
	txa
	and #7
	bne :-
	_nomem_return_sparse_x nomem_putc, nomem_putc_count

nomem_putc_lab:
:	lda font+32*8,Y
	sta screen_ofs,X
	iny
	inx
	txa
	and #7
	bne :-
	_nomem_return_sparse_x nomem_putc_lab, nomem_putc_lab_count
	