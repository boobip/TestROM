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
	
	.segment "ZEROINIT": zeropage
	popcount: .res 1
	poptmp: .res 1

	.segment "CODE"
;;	.segment "OVL1"

	.import hex2ascii_lut

.importzp outfn_
.export outfn
outfn:
	jmp (outfn_)


;; on entry X/Y? points to 32 bit number in zero page
;; npad, pad cha, radix, number

	.export hextoa
.proc hextoa
	mask = _r0
	num0 = _r1
	num1 = _r2
	num2 = _r3
	num3 = _r4
	npad = _r5
	cpad = _r6
;mask = _r7
	ndigit = num0
	
	ldy #0
	
; loop & shift & mask & push

next_digit:
	lda mask
	sta _tmp0
	and num0
	tax
	lda hex2ascii_lut,X
	pha
	iny
	
:	lsr num3
	ror num2
	ror num1
	ror num0
	lsr _tmp0	;; shift right n times by number of bits in mask
	bne :-
	
	lda num0
	ora num1
	ora num2
	ora num3
	bne next_digit

	;; all digits pushed to stack, number of digits in Y
	
	lda cpad
	bne :++
	
:	pha
	iny	
:	cpy npad
	bcc :--

.endproc

enough_padding:

	;; Remove chars from stack and send to outfn
	;; on entry: number chars to pop in Y
	.export poptooutfn
poptooutfn:
	sty popcount
	sty poptmp

	;; done padding, output number
:	pla
	sta _r0		;; calling convention: value in r0 
	jsr outfn
	dec poptmp
	bne :-
	
	lda popcount
;;	sta _r0	; return total number of digits _r0
	rts
	
	
	.export dectoa
.proc dectoa
	neg = _r0
	num0 = _r1
	num1 = _r2
	num2 = _r3
	num3 = _r4
	npad = _r5
	cpad = _r6
	prtemp = _tmp0

            LDY #0         ;; Digit counter
prdecdigit: LDA #32        ;; 32-bit divide
            STA prtemp
            LDA #0         ;; Remainder=0
            CLV            ;; V=0 means divide result = 0
prdecdiv10: CMP #10/2      ;; Calculate OSNUM/10
            BCC prdec10
            SBC #10/2+$80  ;; Remove digit & set V=1 to show div result > 0
            SEC            ;; Shift 1 into div result
prdec10:    ROL num0        ;; Shift /10 result into OSNUM
            ROL num1
            ROL num2
            ROL num3
;; Can continue to arbitary size by adding more zero page locations
;;
            ROL A          ;; Shift bits of input into acc (input mod 10)
            DEC prtemp
            BNE prdecdiv10 ;; Continue 32-bit divide
            ORA #'0'       ;; Convert to ASCII character
            PHA            ;; Push low digit 0-9 to print
            INY            ;; Increase number of digits
            BVS prdecdigit ;; If V=1, result of /10 was >0, do next digit

			cpy npad
			bcs emit_minus
			

; if neg & pad '0' then pad + push -
; if neg & pad ' ' push - then pad
	lda neg
	beq pad
	
	lda cpad
	cmp #' '		;; C set here
	beq emit_minus
	dec npad

pad:
	lda cpad
	bne :++
	
:	pha
	iny	
:	cpy npad
	bcc :--

emit_minus:
	lda neg
	beq :+
	lda #'-'
	pha
	iny

	lda #0
	sta neg		;; dealt with neg

:	cpy npad
	bcc pad
	bcs enough_padding	;; use tail of hextoa
.endproc
	
