
;; 1.042ms per byte at 9600, 2084 cycles per char @ 2MHz

;;=====================================
;; Serial initialisation constants
;;

baud = 76800
;;baud = 9600

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
;; serial helper macros
;;

.MACRO _tx_wait
	.local loop
	lda #10 ; tx buf empty (2) or CTS high (8) (don't block on disconnected serial)
loop:
	bit acia
	beq loop
.ENDMACRO

.MACRO _tx_wait_timeout_y ; 12 bytes
	.local loop, ok
	ldy #(2000000*10/(baud*15)+1) ; 15 cycle loop
loop:
	lda acia		;; 4
	lsr				;; 2
	lsr				;; 2
	bcs ok			;; 2 - not taken
	dey				;; 2
	bne loop		;; 3 - taken
ok:
.ENDMACRO

.MACRO _tx_wait_timeout_old ; 14 bytes
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

;; only trashes A
.MACRO _tx_wait_timeout ; 16 bytes
	.local loop, decimal, timeout, n
	n = (2000000*10/(baud*9)+1) ; 9 cycle loop
	lda acia		;; 4
	and #2
	bne timeout
	txa				;; stash x
	ldx #n
loop:
	nop				;; 2
	nop				;; 2
	dex				;; 2
	bne loop		;; 3 - taken
	tax				;; restore x
timeout:
.ENDMACRO

;; only trashes X
.MACRO _tx_wait_timeout_trashX ; 16 bytes
	.local loop, decimal, timeout, n
	n = (2000000*10/(baud*9)+1) ; 9 cycle loop
	tax
	lda acia		;; 4
	lsr
	lsr
	txa				;; restore A
	bcs timeout
	ldx #n
loop:
	nop				;; 2
	nop				;; 2
	dex				;; 2
	bne loop		;; 3 - taken
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

.MACRO _zp_ser_puts str
	.local ptr,relptr
	.PUSHSEG
	.segment "STRINGS"
	ptr: .byte str,0
	.POPSEG
	relptr = <(ptr-__STRINGS_LOAD__)
	
	ldy #relptr
	_zp_call zp_ser_puts

.ENDMACRO
