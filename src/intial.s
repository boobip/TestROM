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

num_pattern = 4
test_pattern:
.byte $ff,$00,$55,$aa,$1,$2,$4,$8,$10,$20,$40,$80,$aa,$55,$ff,$00

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

; model B serial registers
acia = $FE08
acia_d = $FE09
serialula = $FE10
baud = 76800

;;=====================================
;; serial helper macros
;;

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

.MACRO _tx_wait
	.local loop
loop:
	lda acia
	and #10 ; tx buf empty or CTS high (don't block on disconnected serial)
	beq loop
.ENDMACRO

.MACRO _tx_byte
	sta acia_d ;write data
.ENDMACRO

;; send string to serial, trashes A
.MACRO _ser_puts msg
	.local msgbuf
	ldx #256-.strlen(msg)
:	
	_tx_wait
	lda msgbuf-256+.strlen(msg),x
	_tx_byte
	inx
	bne :-
	beq :+
msgbuf: .byte msg,"X"
:
.ENDMACRO

;; send a hardcoded character, trashes A
.MACRO _ser_putc c
	_tx_wait
	lda #c
	sta acia_d	
.ENDMACRO

;; send number in X as hex to serial, trashes A
.MACRO _ser_phex reg
	_tx_wait
	reg
	lsr a
	lsr a
	lsr a
	lsr a
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
	_tx_byte
	_tx_wait
	reg			; restore value
	and #$0F
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
	_tx_byte
	reg			; restore A
.ENDMACRO


;;=====================================
;; intial memory test error handler
;;

err_row = 5
err_zp_screen_ofs = 40*8*err_row
err_s_screen_ofs = 40*8*(err_row+4)
font_zero_p = font+8*('0'-' ')

.MACRO _mem_error page, screenofs
	cld		; decimal mode messes with phex
	txs		; stash test pattern index in S
			; doesn't matter that we overwrite S, same pattern different loop
	
	tax					;; mov read memory value to X
	_ser_putc $a
	_ser_phex txa		;; serial out
	
	tsx
	eor test_pattern,X	;; make bitmask for bad bits	
	tax					;; move bitmask to X
	
	_ser_putc '@'
	_ser_putc '0'
	_ser_putc page
	_ser_phex tya			;; send address of failure

	_ser_putc ' '
	_ser_putc '('

.REPEAT 8, I
	txa
	lsr a
	tax					;; stash bad bits
	bcs :+
	;; not in error
	_ser_putc '0'+I
	bne :++				;; always true
:
	.REPEAT 8, J
		LDA font+8*('X'-' ')+J
		STA screenofs+8*(40+I)+J
	.ENDREP
	_ser_putc 'X'
:	
.ENDREP


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
	lda font+8*('0'-' ')+J,X
	sta screenofs+8*(40+10)+J
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
	lda font+8*('0'-' ')+J,X
	sta screenofs+8*(40+11)+J
.ENDREP

	_ser_puts ") expected "
	tsx
	lda test_pattern,x
	tax
	_ser_phex txa

	tsx			;; pattern index back in X, address still in Y continue mem test
	sed		; flag error
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
	_ser_puts "BooBip TestROM\n"

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
	_ser_puts "Test zero page & stack"

;; init bit positions on screen
	ldx #0
:	lda font_zero_p,X
	sta err_zp_screen_ofs,X
	sta err_s_screen_ofs,X
	inx
	cpx #8*8				; 8 bit positions
	bne :-

;; test zero page & stack

	ldx #0
zpstackloop:
	txs		; stash pass count in S
	txa
	and #15 ; mask out pattern
	tax		; pattern index in X
	lda test_pattern,X
	
	ldy #0
:	sta $00,y	;; write pattern to ZP
	sta $100,y	;; write pattern to STACK
	iny
	bne :-

:	lda $00,Y
;eor #$aa ;; bodge to test error display
	cmp test_pattern,X
	beq zp_error_return
	jmp zp_error	;; BAD ZP memory location
zp_error_return:

	lda $100,Y
;eor #$55 ;; bodge to test error display
	cmp test_pattern,X 
	beq stack_error_return
	jmp stack_error	;; BAD STACK memory location
stack_error_return:
	
	iny
	bne :-
	
	tsx		;; fetch pass counter
	inx	
	bne zpstackloop
	lda #$99
	adc #1			; add in decimal mode will set carry
	bcc :+
	jmp zpstackloop ;; seen an error... spin forever
:	;; decimal mode still clear set so RAM test completed


;; ZP & STACK passed the test	
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
	txs			; intialise stack pointer
	
	jmp back2mos

	jmp rst_handler_3 ;; go to C code

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

back2mos:
	sei
	ldx #0
:	lda back2moslow,X
	sta $200,x
	inx
	cpx #(back2mos-back2moslow)
	bne :-
	ldx #0
	stx $fffc
	ldx #2
	stx $fffd
:	jmp :- ;; spin wait for RESET

	
zp_error:
	_mem_error '0', err_zp_screen_ofs	
	jmp zp_error_return;

stack_error:
	_mem_error '1', err_s_screen_ofs
	jmp stack_error_return;


