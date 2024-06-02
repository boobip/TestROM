	.include "_nostack.inc"
	.include "_zeropage.inc"

	.import __ADDRLUTHI_LOAD__, __ADDRLUTLO_LOAD__


	.export zp_return_0, zp_return_1, zp_return_2, zp_return_3, zp_return_4
	

	;; n times dex for args
zp_return_4:
	dex
zp_return_3:
	dex
zp_return_2:
	dex
zp_return_1:
	dex
zp_return_0:
	dex
	sta sa_
	lda __ADDRLUTHI_LOAD__,Y
	sta ret_+1
	lda __ADDRLUTLO_LOAD__,Y
	sta ret_
	lda sa_
	ldy sy_
	jmp (ret_)
	
	



