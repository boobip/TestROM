	.include "_nostack.inc"
	.include "_zeropage.inc"

	.import __ADDRLUTHI_LOAD__, __ADDRLUTLO_LOAD__


	.export zp_return
		
	
zp_return:
	sta sa_
	tsx				;; restore current ZP stack pointer
	lda $fe,X		;; load return index
	tax
	lda __ADDRLUTHI_LOAD__,X
	sta ret_+1
	lda __ADDRLUTLO_LOAD__,X
	sta ret_

	tsx				;; restore current ZP stack pointer
	lda $ff,X		;; load callee ZP stack pointer
	tax
	txs				;; restore callee ZP stack pointer
	
	lda sa_
	jmp (ret_)
