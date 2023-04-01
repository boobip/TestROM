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


num_pattern = 4
test_pattern:
.byte 00,$ff,$55,$aa,$1,$2,$4,$8,$10,$20,$40,$80

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
	sta a:$2700,X
	sta a:$2800,X
	sta a:$2900,X
	sta a:$2a00,X
	sta a:$2b00,X
	sta a:$2c00,X
	sta a:$2d00,X
	sta a:$2e00,X
	sta a:$2f00,X ;; 12k - mode 4 is 10K
	inx
	beq :+
	jmp :-
:

;; test junk

	ldx #0
:	lda $c000+65*8,x
	sta 40*10*8,x
	inx
	bne :-
	

	
	
	

;; test zero page


	
	


;	jmp rst_handler_2
;; fall through to reset handler 2
	
;;=====================================
;; follow on reset handler
;; ZP & stack tested OK
;;
	.export rst_handler_2
rst_handler_2:
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
	

