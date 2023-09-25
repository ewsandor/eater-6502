; Root EEPROM file

  include definitions.s
  include system.s
  include static_data.s
  include wozmon.s

vector_table:
; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word irqb