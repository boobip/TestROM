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

.MACRO _pause_us n
	ldy # >((n*10)/4-1)	;4 loops ~20 cycles or 10us at 2MHz
	ldx # <((n*10)/4)
:	dex				;2
	bne :-			;3 inner loop
	dey
	bne :-
.ENDMACRO

.MACRO _pause_ms n
	_pause_us n*1000
.ENDMACRO

.MACRO _jsr_zeropage ptr, func
	.local ret
	lda #<ret
	sta ptr
	lda #>ret
	sta ptr+1
	jmp func
ret:
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

