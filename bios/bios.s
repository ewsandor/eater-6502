; Root EEPROM file

  .feature org_per_seg

  .include "definitions.s"
  .include "system.s"
  .include "syscall.s"
  .include "static_data.s"
  .include "wozmon.s"

.segment "VECTOR_TABLE"
; Vector Table
  .word nmib
  .word reset
  .word irqb