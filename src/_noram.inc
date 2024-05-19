;;=====================================
;; 
;;

.MACPACK longbranch

;;=====================================
;; Call subroutine
;; label = routine
;; counter = holds n calls
;; const = (optional) store const @ label_const,X
;;
.MACRO _nomem_call label, counter, const
	.IFNDEF counter
		counter .set 0
	.ENDIF
	.IFNBLANK const
		.ident(.sprintf("%s%02d_const",.string(label),counter)) = const
	.ENDIF

	ldx #counter
	jmp label
	.export .ident(.sprintf("%s%02d_return",.string(label),counter))
	.ident(.sprintf("%s%02d_return",.string(label),counter)):
	counter .set counter+1
.ENDMACRO

;;=====================================
;; Emit no memory subroutine return code & const table
;;
.MACRO _nomem_return label, counter
.REPEAT counter-1, I
	cpx #I
	jeq .ident(.sprintf("%s%02d_return",.string(label),I))
.ENDREP
	jmp .ident(.sprintf("%s%02d_return",.string(label),counter-1))


;; emit constants table if we have one
.IFDEF .ident(.sprintf("%s%02d_const",.string(label),0))
	.PUSHSEG
	.RODATA
	.export .ident(.concat(.string(label),"_const"))
	.ident(.concat(.string(label),"_const")):
	.REPEAT counter, I
		.byte .ident(.sprintf("%s%02d_const",.string(label),I))
	.ENDREP
	.POPSEG
.ENDIF

.ENDMACRO


;;=====================================
;; No memory call, sparse version
;;

.MACRO _nomem_call_sparse label, counter, rval
	.IFNDEF counter
		counter .set 0
	.ENDIF
	.ident(.sprintf("%s%02d_rval",.string(label),counter)) = rval
	jmp label
	.export .ident(.sprintf("%s%02d_return",.string(label),counter))
	.ident(.sprintf("%s%02d_return",.string(label),counter)):
	counter .set counter+1
.ENDMACRO


.MACRO _nomem_return_sparse label, counter

.REPEAT counter-1, I
	cmp #.ident(.sprintf("%s%02d_rval",.string(label),I))
	jeq .ident(.sprintf("%s%02d_return",.string(label),I))
.ENDREP
	jmp .ident(.sprintf("%s%02d_return",.string(label),counter-1))
	
.ENDMACRO

.MACRO _nomem_return_sparse_x label, counter

.REPEAT counter-1, I
	cpx #.ident(.sprintf("%s%02d_rval",.string(label),I))
	jeq .ident(.sprintf("%s%02d_return",.string(label),I))
.ENDREP
	jmp .ident(.sprintf("%s%02d_return",.string(label),counter-1))
	
.ENDMACRO