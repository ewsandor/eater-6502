; Walk through EEPROM padded with NOPs 255 times (~16 seconds at 1MHz), then halt



; Non-Maskable Interrupt Vector Address
NMIB_VECTOR=$fffa
; Reset Vector Address
RESB_VECTOR=$fffc
; Interrupt Vector Address
IRQB_VECTOR=$fffe

; 6522 VIA Registers
VIA_PORTB    = $6000 ; Output/Input Register B
VIA_PORTA    = $6001 ; Output/Input Register A
VIA_DDRB     = $6002 ; Data Direction Register B
VIA_DDRA     = $6003 ; Data Direction Register A
VIA_T1CL     = $6004 ; Timer 1 Low-Order Latches/Counter
VIA_T1CH     = $6005 ; Timer 1 High-Order Counter
VIA_T1LL     = $6006 ; Timer 1 Low-Order Latches
VIA_T1LH     = $6007 ; Timer 1 High-Order Latches
VIA_T2CL     = $6008 ; Timer 2 Low-Order Latches/Counter
VIA_T2CH     = $6009 ; Timer 2 High-Order Counter
VIA_SR       = $600A ; Shift Register
VIA_ACR      = $600B ; Auxillary Control Register
VIA_PCR      = $600C ; Peripheral Control Register
VIA_IFR      = $600D ; Interrupt Flag Register
VIA_IER      = $600E ; Interrupt Enable Registser
VIA_PORT_NHS = $600F ; Output/Input Register A except no "Handshake"

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
  sei                 ; Disable interrupts
  ; Clear zero page and stack
  lda #$00            ; Load accumulator with empty byte
  ldx #$FF            ; Start with max X offset (This will sweep starting at zp+255)
clear_zp_stack:
  sta   $00,x         ; Clear zero page with X offset
  sta $0100,x         ; Clear stack with X offset
  dex                 ; Decrement X
  cpx #$FF            ; Compare X to 0xFF to detect wrap around
  bne clear_zp_stack  ; If X has not wrapped around, continue in loop
  ; Reset Complete
main:
  lda #$00
  sta VIA_IER   ; Disable all interrupts
  sta VIA_PORTA ; Clear PORTA
  sta VIA_PORTB ; Clear PORTB
  lda #$FF
  sta VIA_DDRA  ; Set all PORTA pins as output
  sta VIA_DDRB  ; Set all PORTB pins as output
  lda #$ED
  sta VIA_PORTA ; Output a specific byte on PORTA
  sta VIA_PORTB ; Output a specific byte on PORTA
  jmp halt ; End of Program

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word resb