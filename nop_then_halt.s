; Walk through EEPROM padded with NOPs 255*255 times, then halt



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
  ldx $FF ; Init X with max value
nop_loop:
  ; ... (nop) ...
  ; ... (nop) ...
  ; ... (nop) ...
  .org (NMIB_VECTOR-9) ; Assume loop handler is 15-bytes (from VASM output)

  dex ; Decrement x
  ; If x > 0, jump back to NOP loop when end of EEPROM is reached.  If x == 0, halt
  bne nop_loop_jmp ; Branch uses relative addressing. Origin beyond max relative address, branch to near by jmp instruction
  jmp halt ; End of program

nop_loop_jmp:
  jmp nop_loop

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word main 
  .org IRQB_VECTOR
  .word resb