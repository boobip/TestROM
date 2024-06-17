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

	.feature string_escapes
	.include "_zeropage.inc"
	.include "_helpers.inc"
	.include "_serial.inc"
	.include "_hardware.inc"

	.segment "OVL0HDR"
	
.export c_stack
c_stack:
	.res $100,0
	
c_stack_top = *-1

	.segment "OVL0"


.export init_entry
init_entry:

	lda #<c_stack_top
	sta _sp0			;; intialise C soft stack
	lda #>c_stack_top
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
	



