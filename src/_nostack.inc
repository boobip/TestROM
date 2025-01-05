zp_ret = $00
zp_par0 = $00
zp_par1 = $01
zp_par2 = $02
zp_par3 = $03
zp_par4 = $04
zp_par5 = $05
zp_par6 = $06
zp_par7 = $07

zp_stack = $18
zp_stack_len = 24

.define _zp_par(n) zp_par0+n,X
.define _zp_stack(n) zp_stack+n

;; initialise stack & stack pointer
.MACRO _zp_initstack n
	.ifnblank n
		ldx #zp_stack+n
	.else
		ldx #zp_stack
	.endif
	txs

.ENDMACRO

	;;
	;; Call ZP function <func> & preserve ntmp locals
	;; preserves Y & stashes A in sa_
	;; X set to stack posn in call and on return, X trampled
	
.MACRO _zp_call func
	.local ret, retptr_hi, retofs

	ldx #retofs		;; trample X with return value
	jmp func
	ret:
		
	.PUSHSEG
	.segment "ADDRLUTHI"
		retptr_hi: .byte >ret
	.segment "ADDRLUTLO"
		.byte <ret
	.POPSEG
	
	retofs = <(retptr_hi - __ADDRLUTHI_LOAD__)

.ENDMACRO

.MACRO _zp_func_prologue func, pars, tmps
	.export func
	.proc func

	sta sa_			;; preserve A
	
	npars_ .set 0
	.ifnblank pars
		npars_ .set .tcount({pars})
	.endif
	
	txa				;; return index to A
	tsx				;; restore ZP stack pointer to X
	sta npars_,X	;; save return posn
	txa				;; callee ZP frame pointer to A
	sta npars_+1,X	;; save current ZP stack pointer
	
	.REPEAT npars_,I
		inx			;; reserve ZP stack space for each par
		.ident(.string(.mid(I,1,{pars}))) .set ($100 - npars_ + I - 2)
	.ENDREP

	ntmps_ .set 0
	.ifnblank tmps
		ntmps_ .set .tcount({tmps})
	.endif
	.REPEAT ntmps_,I
		.ident(.string(.mid(I,1,{tmps}))) .set I
	.ENDREP
	
	inx				;; reserve ZP stack space for return posn
	inx				;; reserve ZP stack space for prev frame pointer
	txs				;; set new ZP stack/frame pointer
		
	lda sa_			;; restore A
.ENDMACRO

.MACRO _zp_func_epilogue
	jmp zp_return
	.endproc
.ENDMACRO