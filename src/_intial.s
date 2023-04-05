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

	
soft_stack = $2ff
	

mode4_ula = $88
mode4_palette:
.byte $07,$17,$27,$37,$47,$57,$67,$77,$80,$90,$a0,$b0,$c0,$d0,$e0,$f0
mode4_crtc:
.byte $3f,$28,$31,$24,$26,$00,$20,$22,$01,$07,$67,$08
.byte >(screen_start),<(screen_start),$00,$00
screen_start=0;$5800/8
video_ula = $fe20
video_ula_palette = $fe21
video_crtc_reg  = $fe00
video_crtc_data = $fe01


;;MODE(s) 	Palette register writes (hex)
;;0, 3, 4, 6 	80 90 A0 B0 C0 D0 E0 F0 07 17 27 37 47 57 67 77
;;1, 5 	A0 B0 E0 F0 84 94 C4 D4 26 36 66 76 07 17 47 57
;;2 	F8 E9 DA CB BC AD 9E 8F 70 61 52 43 34 25 16 07

;; CRTC @ $c46e in MOS

.MACRO _zp_puts msg
	ldx #256-.strlen(msg)
:	lda msgbuf-256+.strlen(msg),x
	sta r2_
	_jsr_zeropage ret_leaf_, zp_putc 
	inx
	bne :-
	beq :+
msgbuf: .byte msg
:
.ENDMACRO



;;=====================================
;; serial helper macros
;;

baud = 76800


; 9600 baud settings
.IF baud=9600
init_acia = $16
init_ula = 100
.ENDIF

; 76800 baud settings
.IF baud=76800
init_acia = $15
init_ula = 64
.ENDIF


;;=====================================
;; Helpers
;;

back2moslow_dst = $28;$200

back2moslow:
	sei
	lda #2
	sta $ff00
	lda #127
	sta $fe4e
;	lda #200
;	ldx #3
;	ldy #0
;	jsr $fff4
	jmp ($fffc)
back2moslowend:	

.MACRO _back2mos
	sei
	ldx #0
:	lda back2moslow,X
	sta back2moslow_dst,x
	inx
	cpx #(back2moslowend-back2moslow)
	bne :-
	ldx #<back2moslow_dst
	stx $fffc
	ldx #>back2moslow_dst
	stx $fffd
.ENDMACRO
;


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


;;=====================================
;; ZP memory test macros & defines
;;

.define mem_error_num  28

.MACRO _mem_error n, pattern
	ldx #n
	jmp mem_error
	.ident(.concat("zpmem_ret",.string(n))):
	.ident(.concat("MEMERRPAT",.string(n))) = pattern
.ENDMACRO

.MACRO _checkboard_fill pattern
	lda #pattern
:	sta $00,Y
	eor #$ff
	iny
	bne :-
.ENDMACRO

.MACRO _checkboard_check pattern, l1, l2
:	lda $00,Y
	cmp #pattern
	beq :+
	_mem_error l1, pattern
:	iny
	lda $00,Y
	cmp #pattern ^ $ff
	beq :+
	_mem_error l2, pattern^$ff
:	iny
	bne :---
.ENDMACRO

.MACRO _march_fill pattern
	lda #pattern
:	sta $00,Y
	iny
	bne :-
.ENDMACRO


.MACRO _march_check pattern, l1
:	lda $00,Y
	cmp #pattern
	beq :+
	_mem_error l1, pattern
:	iny
	bne :--
.ENDMACRO

;; march C- extended
;; ↕(w0); ↑(r0,w1,r1); ↑(r1,w0);
;; ↓(r0,w1); ↓(r1,w0); ↕(r0)
.MACRO _march_cminus_extended pattern, l1
	_march_fill pattern

;; ↑(r0,w1,r1);
:	lda $00,Y
	cmp #pattern
	beq :+
	_mem_error (0+l1), pattern
:	lda #pattern^$ff
	sta $00,Y
	lda $00,Y
	cmp #pattern^$ff
	beq :+
	_mem_error (1+l1), pattern^$ff
:	iny
	bne :---

;; ↑(r1,w0);
:	lda $00,Y
	cmp #pattern^$ff
	beq :+
	_mem_error (2+l1), pattern^$ff
:	lda #pattern
	sta $00,Y
	iny
	bne :--

;; ↓(r0,w1);
:	dey
	lda $00,Y
	cmp #pattern
	beq :+
	_mem_error (3+l1), pattern
:	lda #pattern^$ff
	sta $00,Y
	tya		;; Z = (y==0)
	bne :--

;; ↓(r1,w0);
:	dey
	lda $00,Y
	cmp #pattern^$ff
	beq :+
	_mem_error (4+l1), pattern^$ff
:	lda #pattern
	sta $00,Y
	tya		;; Z = (y==0)
	bne :--

;; ↕(r0)
	_march_check pattern, (5+l1)
.ENDMACRO

;;=====================================
;; initial reset handler
;; assume no memory works, no JSR
;;

	.export rst_handler
rst_handler:
	sei
	cld

;; setup video, mode 4
	lda #mode4_ula
	sta video_ula
	ldx #15
:	lda mode4_palette,X
	sta video_ula_palette
	dex
	bpl :-
	ldx #15
:	lda mode4_crtc,X
	stx video_crtc_reg
	sta video_crtc_data
	dex
	bpl :-

;; now in mode 4

;; initialise serial 9600
	lda #init_acia
	sta acia
	lda #init_ula
	sta serialula
	_ser_puts "\nBooBip TestROM\n"

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
	_ser_puts "Test zero page"


;; test zero page



zpstackloop: ;; TODO: RENAME LATER

;; checkerboard test
	ldy #0
zp_check:
	_checkboard_fill $55
	_pause_ms 10
	_checkboard_check $55, 0, 1

	_checkboard_fill $AA
	_pause_ms 10
	_checkboard_check $AA, 2, 3

	;; march test 00,0F,33,55
zp_march:
	_march_cminus_extended $55, 4
	_march_cminus_extended $0f, 10
	_march_cminus_extended $33, 16
	_march_cminus_extended $00, 22

	;; check if D flag is set
	lda #$99
	adc #1			; add in decimal mode will set carry
	bcc :+
	jmp zpstackloop ;; seen an error... spin forever
:	;; decimal mode still clear set so RAM test completed


	;; ZP passed the test	
	_ser_puts ", OK\n"
	
	;; DEBUG
	_back2mos

	
seed = $b00b19
	_random_seed seed
	
	;; check for 16/32KB by memory alias
	lda #$80
	sta memsize_
	lsr
	sta a:memsize_ + $4000
	
	;; feedback to user
	
	lda #8*8
	sta dst_
	lda #0
	sta dst_+1		;; setup text destination
	
	lda memsize_
	sta e_
	bmi full32KB
	_ser_puts "16KB detected\nTesting &0100-&3FFF"
	ldx #$16		
	jmp run_memtest
full32KB:
	_ser_puts "32KB detected\nTesting &0100-&7FFF"
	ldx #$32
run_memtest:

	;; print memory size on screen
	_jsr_zeropage ret1_, zp_phex

	;; show bit positions on screen
	_zp_puts "KB vv@aaaa 76543210 ee"
	
	lda #1
	sta s_			;; boot mem test start from stack $100
	sta k_			;; do 1 pass of memory test		
	lda memsize_
	sta e_			;; boot mem test do all detected
		
	;; do memory test
	_jsr_zeropage ret_mem_, mem_test

	;; System memory passed the test
	lda r3_
	bne rst_handler_2	;; skip printing OK if memory fault
	_ser_puts ", OK\n"

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
	
	sta _sp0			;; intialise C soft stack
	lda #>__STACKTOP__
	sta _sp1
	

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
;;	X - return point/pattern
;;	Y - ZP address
;;	
;;

err_row = 5
screen_ofs = 40*8*err_row
font_zero_p = font+8*('0'-' ')

; got... read, addr, pat
; regs... a, x, y, s

mem_error:
	cld				;; decimal mode messes with phex
	txs				;; stash ret/pat in S
	
	tax				;; stash rval/pattern in X
	_ser_putc $a
	_ser_phex txa	;; serial out what was read
	
	_ser_putc '@'
	_ser_putc '0'
	_ser_putc '0'
	_ser_phex tya			;; send address of failure

	_ser_putc ' '
	_ser_putc '('
	
	txa					;; restore read value to A
	tsx					;; mov ret/pat to X
	eor mem_patterns,X	;; make bitmask for bad bits
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
		STA screen_ofs+8*(40+I)+J
	.ENDREP
	_ser_putc 'X'
:	
.ENDREP

	_ser_puts ") expected "
	tsx
	lda mem_patterns,x
	tax
	_ser_phex txa

;; print last error address on screen
	tya
	lsr a
	lsr a
	lsr a
	lsr a
	cmp #$0A
	bcc :+
	adc #$06
:
	asl		; mul 8 to get font char offset
	asl
	asl
	tax		
.REPEAT 8, J
	lda font_zero_p+J, X
	sta screen_ofs+8*(40+10)+J
.ENDREP
	tya
	and #$0F
	cmp #$0A
	bcc :+
	adc #$06
:
	asl		; mul 8 to get font char offset
	asl
	asl
	tax
.REPEAT 8, J
	lda font_zero_p+J,X
	sta screen_ofs+8*(40+11)+J
.ENDREP

;; init bit positions on screen
	ldx #0
:
.REPEAT 8, I
	lda font_zero_p+8*(7-I),x
	sta screen_ofs+8*I,x
.ENDREP
	inx
	cpx #8
	bne :-

	tsx		;; pattern index back in X, address still in Y continue mem test
	sed		; flag error

;; return to correct point in memory test
.REPEAT mem_error_num-1, I
	cpx #I
	bne :+
	jmp .ident(.concat("zpmem_ret",.string(I)))
:
.ENDREP
	jmp .ident(.concat("zpmem_ret",.string(mem_error_num-1)))



;; build memory patterns to match with error labels
mem_patterns:
.REPEAT mem_error_num, I
	.byte .ident(.concat("MEMERRPAT",.string(I)))
.ENDREP




