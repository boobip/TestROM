
;;=====================================
;; serial helper macros
;;

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
