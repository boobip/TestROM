*fx3,6
*fx203,32
MODE7
*fx181,0
*fx230,1

NEW
AUTO
REM Install
MODE 7:HIMEM=HIMEM-&4000
DIM mc 512
bank%=0
bank2%=bank% EOR 1
PROCmode_rom:REM start from known mode
PROCmode_romram
REM load Test ROM
PRINT"Load test ROM"
OSCLI("LOAD test 3C00")
PRINT"Assemble init"
PROCbank(bank2%)
PROCassemble
PRINT"Run init"
!&70=&3C00
!&72=&C000
CALL init
STOP
DEFPROCmode_rom:?&FF00=2:ENDPROC
DEFPROCmode_romram:!&FF00=&60002:ENDPROC
DEFPROCmode_ram(B%):?&FF00=4+B%:ENDPROC
DEFPROCbank(B%):?&FF00=8+B%:ENDPROC
DEFPROCbankwrite(B%):?&FF00=&A+B%:ENDPROC
DEFPROCbankread(B%):?&FF00=&C+B%:ENDPROC
DEFPROCbankrnw(B%):?&FF00=&E+B%:ENDPROC
REM assemble irq handler and init
DEFPROCassemble
FORpass%=0TO3STEP3
  P%=mc
  [opt pass%
  .init
  lda #8+bank%:sta &FF00 \ set TestROM bank
  ldy #0
  .cploop
  lda (&70),Y:sta (&72),Y:iny:bne cploop
  inc &71
  inc &73:lda &73:cmp #&FC:bne cploop
  sei:lda #4+bank2%:sta &FF00:jsr inithigh \RAM exec
  lda #4+bank%:sta &FF00:jmp (&FFFC) \ jump to TestROM reset handler
  ]
  P%=&C000
  [opt pass%
  .inithigh
  ldx #0
  .tploop:lda &7B00,X:sta &FF00,X:inx:bne tploop \copy top page
  RTS
  ]
  NEXT
ENDPROC




*FX230,0
*FX3,5
SAVE"LOADER"
*FX2,0
