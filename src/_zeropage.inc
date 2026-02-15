	.pushseg
	.segment "ZEROINIT":zeropage

;;=====================================
;; Macro to emit/import varialbe
;;

.MACRO _zpvar name, size
	.ifdef 	EMITZPVARS
		.if EMITZPVARS=1
			.exportzp name
		.endif
		name:
		.res size
	.ELSE
		.importzp name
	.ENDIF
.ENDMACRO

.define _zp_byte(name) _zpvar name, 1
.define _zp_word(name) _zpvar name, 2
.define _zp_dword(name) _zpvar name, 4
.define _zp_struct(name,type) _zpvar name, .sizeof(type)

;;=====================================
;; Type definitions
;;

.struct TStruct
	_x .word
	_y .word
.endstruct

;.ifdef 	EMITZPVARS
;	.exportzp _myzpstruct
;_myzpstruct: .tag TStruct
;.ENDIF


;;=====================================
;; Variable declarations
;;

;; unused sx_

	_zp_byte	sa_
;;	_zp_byte	sx_
;;	_zp_byte	sy_
	_zp_word	src_
	_zp_word	dst_
	_zp_word	ret_
	_zp_byte	memsize_
	_zp_byte	current_bank_
	_zp_dword	seed_
	_zp_word	nmicount_
	
;	_zp_byte	zp_stack_ptr_

;	_zp_struct _zpa, zpargs_t

;	_zp_byte _myzp



	.ifdef 	EMITZPVARS
		.exportzp zp_stack
	.endif
	
	.popseg



;.undefine _zp_byte
;.undefine _zp_word
;.undefine _zp_dword
;.undefine _zp_struct
