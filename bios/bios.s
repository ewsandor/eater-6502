; Root EEPROM file

  .include "definitions.s"
  .include "system.s"
  .include "static_data.s"
  .include "wozmon.s"

.segment "VECTOR_TABLE"
; Vector Table
  .word nmib
  .word reset
  .word irqb