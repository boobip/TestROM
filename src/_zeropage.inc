	.pushseg
	.segment "ZEROPAGE"

;;=====================================
;; Macro to emit/import varialbe
;;

.ifdef 	EMITZPVARS
	.MACRO _zpvar name, size
		.exportzp name
		name:
		.res size
	.ENDMACRO
.ELSE
	.MACRO _zpvar name, size
		.importzp name
	.ENDMACRO
.ENDIF

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

;; unused j_, sa_

	_zp_word	p_
	_zp_byte	s_
	_zp_byte	e_
	_zp_byte	n_
	_zp_byte	i_
	_zp_byte	j_
	_zp_byte	k_
	_zp_word	ret1_
	_zp_word	ret_mem_err_
	_zp_word	ret_mem_
	_zp_word	ret_leaf_
	_zp_byte	sa_
	_zp_byte	sx_
	_zp_byte	sy_
	_zp_byte	r0_
	_zp_byte	r1_
	_zp_byte	r2_
	_zp_byte	r3_
	_zp_dword	seed_
	_zp_dword	sseed_
	_zp_word	src_
	_zp_word	dst_
	_zp_byte	memsize_

;	_zp_struct _zpa, zpargs_t

;	_zp_byte _myzp


	.popseg

.undefine _zp_byte
.undefine _zp_word
.undefine _zp_dword
.undefine _zp_struct
