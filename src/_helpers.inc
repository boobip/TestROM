	;; https://beebwiki.mdfs.net/Converting_Binary_Coded_Decimal
	;\ Convert binary number to BCD
	;\ ----------------------------
	;\ On entry, A=value 0-99
	;\ On exit,  A=BCD value &00-&99
	;\           X corrupted
.MACRO _bin2bcd
BINtoBCD:
	TAX             ;;\ Transfer number to X
	LDA #&99        ;;\ Start with -1 in BCD form
	SED             ;;\ Switch to Decimal arithmetic
BINtoBCDlp:         ;;
	CLC             ;;
	ADC #1      	;;\ Add 1 with BCD arithmetic
	DEX             ;;\ Decrement input value in X
	BPL BINtoBCDlp  ;;\ Loop until input value < 0
	CLD				;;\ Switch back to Binary arithmetic
.ENDMACRO

.MACRO _mul10 tmp
	asl
	sta tmp
	asl
	asl
	clc
	adc tmp
.ENDMACRO

;; STILL BUGGY?
.MACRO _pause_us n
	.local loops
	loops = (2*n-4)/5	;; number of 5 cycle loops
	ldy # 1+>(loops+1)
	ldx # <(loops+1)
:	dex				;2
	bne :-			;3 inner loop
	dey
	bne :-
.ENDMACRO

.MACRO _pause_ms n
	_pause_us n*1000
.ENDMACRO


.MACRO _pause_us_ay n
	.local loops
	loops = (2*n-8)/9	;; number of 9 cycle loops
	ldy #<loops
	lda #>loops
:	cpy #1			;; 2
	dey				;; 2
	sbc #0			;; 2
	bcs :-			;; 3
.ENDMACRO

.MACRO _pause_ms_ay n
	_pause_us_ay n*1000
.ENDMACRO

.MACRO _mov_dword dst, src
	lda src
	sta dst
	lda src+1
	sta dst+1
	lda src+2
	sta dst+2
	lda src+3
	sta dst+3
.ENDMACRO

.MACRO _mov_dword_imm dst, src
	lda #<(.LOWORD(src))
	sta dst
	lda #>(.LOWORD(src))
	sta dst+1
	lda #<(.HIWORD(src))
	sta dst+2
	lda #>(.HIWORD(src))
	sta dst+3
.ENDMACRO

;;
;;  HEX -> ASCII (decimal mode)

.MACRO _hex2ascii_dec_hi ;; 8 bytes
  lsr
  lsr
  lsr
  lsr
  cmp #9+1
  adc #$30
.ENDMACRO

.MACRO _hex2ascii_dec_lo ;; 6 bytes
  and #$0F
  cmp #9+1
  adc #$30
.ENDMACRO

.MACRO _hex2ascii_bin_hi ;; 12 bytes
	lsr
	lsr
	lsr
	lsr
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
.ENDMACRO

.MACRO _hex2ascii_bin_lo ;; 10 bytes
	and #$0F
	cmp #$0A
	bcc :+
	adc #$06
:
	adc #$30
.ENDMACRO

.MACRO _hex2ascii_lut reg ;; 4 bytes
	.if .match(reg,X)
		tax
	.else
		tay
	.endif
	lda hex2ascii_lut,reg
.ENDMACRO

.MACRO _hex2ascii_lut_hi reg ;; 8 bytes
	lsr
	lsr
	lsr
	lsr
  _hex2ascii_lut reg
.ENDMACRO

.MACRO _hex2ascii_lut_lo reg ;; 6 bytes
  and #$0F
  _hex2ascii_lut reg
.ENDMACRO

.MACRO _bitzp
	.byte $24
.ENDMACRO

.MACRO _bitabs
	.byte $2c
.ENDMACRO



