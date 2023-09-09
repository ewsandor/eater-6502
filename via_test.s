; Walk through EEPROM padded with NOPs 255 times (~16 seconds at 1MHz), then halt



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

reset:
  ; Clear zero page and stack
  lda #$00            ; Load accumulator with empty byte
  ldx #$FF            ; Start with max X offset (This will sweep starting at zp+255)
clear_zp_stack:
  sta  $00,x          ; Clear zero page with X offset
  sta $100,x          ; Clear stack with X offset
  dex                 ; Decrement X
  cpx #$FF            ; Check if X wrapped around (to include X == 0)
  bne clear_zp_stack  ; If X has not wrapped around, continue in loop
  ; Reset Complete
main:
  ldx #$FF            ; Init X with max value
nop_loop:
  ; ... (nop) ...
  ; ... (nop) ...
  ; ... (nop) ...
  .org (NMIB_VECTOR-9) ; Assume loop handler is 9-bytes (from VASM output)

  dex ; Decrement x
  ; If x > 0, jump back to top of NOP loop when end of EEPROM is reached.  If x == 0, halt
  bne nop_loop_jmp ; Branch uses relative addressing. EEPROM origin beyond max relative address, branch to near by jmp instruction
  jmp halt ; End of program

nop_loop_jmp:
  jmp nop_loop

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word resb