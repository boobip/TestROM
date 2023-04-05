;
; 6502 LFSR PRNG - 32-bit
; Brad Smith, 2019
; http://rainwarrior.ca
;

; A 32-bit Galois LFSR

; Possible feedback values that generate a full 4294967295 step sequence:
; $AF = %10101111
; $C5 = %11000101
; $F5 = %11110101

; $C5 is chosen

	.importzp seed_
	.importzp ret_leaf_
	.export galois32o

; overlapped
; 83 cycles
; 44 bytes

galois32o:
	; rotate the middle bytes left
	ldx seed_+2 ; will move to seed_+3 at the end
	lda seed_+1
	sta seed_+2
	; compute seed_+1 ($C5>>1 = %1100010)
	lda seed_+3 ; original high byte
	lsr
	sta seed_+1 ; reverse: 100011
	lsr
	lsr
	lsr
	lsr
	eor seed_+1
	lsr
	eor seed_+1
	eor seed_+0 ; combine with original low byte
	sta seed_+1
	; compute seed_+0 ($C5 = %11000101)
	lda seed_+3 ; original high byte
	asl
	eor seed_+3
	asl
	asl
	asl
	asl
	eor seed_+3
	asl
	asl
	eor seed_+3
	stx seed_+3 ; finish rotating byte 2 into 3
	sta seed_+0
	jmp (ret_leaf_)
;	rts
