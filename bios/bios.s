; Root EEPROM file

  .feature org_per_seg

  .include "definitions.s"
  .include "syscall.s"
  .include "static_data.s"

.segment "VECTOR_TABLE"
  .import NMIB
  .import RESET_LBL
  .import IRQB
; Vector Table
  .word NMIB
  .word RESET_LBL
  .word IRQB