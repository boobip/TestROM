
;; 1.042ms per byte at 9600, 2084 cycles per char @ 2MHz
.define TXTIMEOUT 

;;=====================================
;; serial helper macros
;;

.MACRO _tx_wait
	.local loop
	lda #10 ; tx buf empty (2) or CTS high (8) (don't block on disconnected serial)
loop:
	bit acia
	beq loop
.ENDMACRO

.MACRO _tx_wait_timeout_old ; 12 bytes
	.local loop, timeout
	ldx #(2000000*10/(baud*15)+1) ; 15 cycle loop
loop:
	lda acia
	asl
	asl
	dex
	beq timeout
	bcc loop
timeout:
.ENDMACRO

.MACRO _tx_wait_timeout ; 14 bytes
	.local loop, timeout
	lda acia
	and #2
	bne timeout
loop:
	clc
	adc #1
	cmp #(2000000*10/(baud*9)+1) ; 9 cycle loop
	bne loop
timeout:
.ENDMACRO



.MACRO _tx_byte
	sta acia_d ;write data
.ENDMACRO



;; send inline string to serial, trashes A, X
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
msgbuf: .byte msg
:
.ENDMACRO

;; send a hardcoded character, trashes A
.MACRO _ser_putc c
	_tx_wait
	lda #c
	sta acia_d	
.ENDMACRO

;; send number in X/Y as hex to serial, trashes A
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
