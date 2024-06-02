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
zp_stack_len = 16

.define _zp_par(n) zp_par0+n,X
.define _zp_stack(n) zp_stack+n

;; initialise stack & stack pointer
.MACRO _zp_initstack n
	.ifnblank n
		ldx #zp_stack+n
	.else
		ldx #zp_stack
	.endif

.ENDMACRO

	;;
	;; Call ZP function <func> & preserve ntmp locals
	;; preserves Y & stashes A in sa_
	
.MACRO _zp_call func
	.local ret, retptr_hi, retofs

	sta sa_
	lda #retofs
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
	
	npars_ .set 0
	.ifnblank pars
		npars_ .set .tcount({pars})
	.endif
	.REPEAT npars_,I
		inx
		.ident(.string(.mid(I,1,{pars}))) .set ($100 - npars_ + I - 1)
	.ENDREP

	ntmps_ .set 0
	.ifnblank tmps
		ntmps_ .set .tcount({tmps})
	.endif
	.REPEAT ntmps_,I
		.ident(.string(.mid(I,1,{tmps}))) .set I
	.ENDREP
	
	sta zp_ret,X
	inx
	lda sa_
.ENDMACRO

.MACRO _zp_func_epilogue
	sty sy_
	ldy $ff,X		;; current stack pointer-1, zp_return decrements X
	jmp .ident(.sprintf("zp_return_%d", npars_))
	.endproc
.ENDMACRO