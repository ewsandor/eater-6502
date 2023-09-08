; Non-Maskable Interrupt Vector Address
NMIB_VECTOR=$fffa
; Reset Vector Address
RESB_VECTOR=$fffc
; Interrupt Vector Address
IRQB_VECTOR=$fffe

; Starting address of EEPROM
EEPROM_START_ADDRESS=$8000
; Start of EEPROM
  .org EEPROM_START_ADDRESS

resb:
nmib:
; Interrupts not expected, fall through to HALT
halt:
  jmp halt ; Remain in infinite do-nothing loop

main:
; Assumes binary built with nop padding ($ea).  Walk through EEROM...
; Jump back to MAIN when end of EEPROM is reached.  Assump JMP instruction is 3-bytes immediately before vector table
  .org (NMIB_VECTOR-$3)
  jmp main

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word main 
  .org IRQB_VECTOR
  .word resb