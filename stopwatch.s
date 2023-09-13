; Simple program to count time since bootup


; Fixed Addresses
; Starting address of EEPROM
EEPROM_START_ADDRESS=$8000
; Starting address of static data block
STATIC_DATA_ADDRESS=$E000
; Non-Maskable Interrupt Vector Address
NMIB_VECTOR=$FFFA
; Reset Vector Address
RESB_VECTOR=$FFFC
; Interrupt Vector Address
IRQB_VECTOR=$FFFE

; 6522 VIA Registers
VIA_PORTB    = $6000 ; Output/Input Register B (PORTB)
VIA_PORTA    = $6001 ; Output/Input Register A (PORTA)
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
; 6522 VIA Constants
VIA_IFR_CA2  = $01
VIA_IFR_CA1  = $02
VIA_IFR_SR   = $04
VIA_IFR_CB2  = $08
VIA_IFR_CB1  = $10
VIA_IFR_T2   = $20
VIA_IFR_T1   = $40
VIA_IFR_ANY  = $80


; LCD Constants
LCD_RS        = $10 ; LCD Register Select on PORT B bit 4
LCD_RW        = $20 ; LCD Read/Write on PORT B bit 5
LCD_EN        = $40 ; LCD Enable on PORT B bit 6
LCD_BUSY      = $08 ; LCD Busy flag on PORT B bit 3
LCD_WRITE_DDR = $7F ; PORTB DDR mask when writing
LCD_READ_DDR  = $70 ; PORTB DDR mask when writing


; System Variables
PUT_STRING_L  = $FC ; Put string Low-Byte
PUT_STRING_H  = $FD ; Put string High-Byte
DELAY_TICKS_L = $FE ; Delay Counter Low-Byte
DELAY_TICKS_H = $FF ; Delay Counter High-Byte



; Start of EEPROM
  .org EEPROM_START_ADDRESS

lcd_init:
  lda #LCD_WRITE_DDR  ; Set first 7-bits (4-data + EN + RW + RS) of PORTB pins as output
  sta VIA_DDRB
  ; Wait 15ms after power-on
  lda #$98  ; Store lower byte of 15ms
  sta DELAY_TICKS_L
  lda #$3A  ; Store upper byte of 15ms
  sta DELAY_TICKS_H
  jsr delay_ticks
  lda #$03  ; Reset LCD using 8-bit mode as upper nibble (See HD44780U Figure 24)
  jsr lcd_write_instruction_nibble
  ; Wait 4.1ms after first write
  lda #$04  ; Store lower byte of 4.1ms
  sta DELAY_TICKS_L
  lda #$10  ; Store upper byte of 4.1ms
  sta DELAY_TICKS_H
  jsr delay_ticks
  lda #$03
  jsr lcd_write_instruction_nibble
  ; Wait 100us after second write
  lda #$64  ; Store lower byte of 100us
  sta DELAY_TICKS_L
  lda #$00  ; Store upper byte of 100us
  sta DELAY_TICKS_H
  jsr delay_ticks
  lda #$03
  jsr lcd_write_instruction_nibble
  ; Enter 4-bit mode and configure LCD
  lda #$02                  ; Send single nibble to enter 4-bit mode
  jsr lcd_write_instruction_nibble
  lda #$28                  ; Set LCD in 4-bit mode with 2 lines
  jsr lcd_write_instruction ; Busy flag will not be valid before 4-bit mode is set
  lda #$01                  ; Clear LCD
  jsr lcd_write_instruction
  lda #$02                  ; Return LCD to home
  jsr lcd_write_instruction
  lda #$06                  ; Set LCD in incrementing mode
  jsr lcd_write_instruction
  lda #$0F                  ; Turn on LCD with blinking cursor
  jsr lcd_write_instruction
  rts


delay_ticks:           ; Blocking delay (tick count set in DELAY_TICKS_L/H)
  pha
  lda VIA_ACR          ; Load current ACR state
  and #$DF             ; Clear Timer-2 control bit (regular iterrupt)
  sta VIA_ACR          ; Updte ACR state
  lda DELAY_TICKS_L    ; Load lower-byte from memory
  sta VIA_T2CL         ; Write Timer-2 counter's lower-byte
  lda DELAY_TICKS_H    ; Load upper-byte from memory
  sta VIA_T2CH         ; Write Timer-2 counter's upper-byte
delay_ticks_wait:
  lda VIA_IFR          ; Read VIA interrupt flag register
  and #VIA_IFR_T2      ; Check if Timer-2 IFR flag is set
  beq delay_ticks_wait ; Loop while interrupt flag is not set (status-reg zero-flag set)
  lda VIA_T2CL         ; Clear interrupt flag
  pla
  rts


lcd_busy_wait:
  pha
  lda #LCD_READ_DDR      ; Set lower nibble of PORTB a input
  sta VIA_DDRB
  lda #LCD_RW            ; Prepare LCD for busy wait
  sta VIA_PORTB
lcd_busy_wait_loop:
  lda #(LCD_EN | LCD_RW) ; Load upper status nibble
  sta VIA_PORTB
  lda VIA_PORTB          ; Read upper status nibble
  pha                    ; Push upper status nibble to stack
  lda #LCD_RW            ; Clear EN flag
  sta VIA_PORTB
  lda #(LCD_EN | LCD_RW) ; Load lower status nibble (Don't care value)
  sta VIA_PORTB          
  lda #LCD_RW            ; Clear EN flag
  sta VIA_PORTB
  pla
  and #LCD_BUSY          ; Check if busy flag is set
  bne lcd_busy_wait_loop ; Remain in loop if busy flag is set
  lda #LCD_WRITE_DDR     ; Restore lower nibble of PORTB as output
  sta VIA_DDRB
  pla
  rts

lcd_write_instruction_nibble:
  pha           ; Push A since it will be modified with enable flag
  sta VIA_PORTB ; Prepare nibble on PORTB
  ora #LCD_EN   ; Prepare nibble with enable flag
  sta VIA_PORTB ; Put nibble on PORTB
  pla           ; Restore A to clear enable
  sta VIA_PORTB ; Clear enable flag
  rts
lcd_write_instruction: ; Write instruction stored in A register
  jsr lcd_busy_wait
  pha ; Push instruction to stack since we will corrupt into nibble
  lsr ; Logical shift right 4-bits
  lsr
  lsr
  lsr
  jsr lcd_write_instruction_nibble ; Write upper nibble
  pla ; Pull original instruction from stack
  pha ; Push original instruction to stack since we will corrupt into nibble
  and #$0F ; Mask the lower nibble
  jsr lcd_write_instruction_nibble
  pla ; Pull original instruction from stack
  rts

lcd_put_char_nibble:
  pha           ; Push A since it will be modified with enable flag
  ora #LCD_RS   ; Set RS bit to write to data register
  sta VIA_PORTB ; Prepare nibbe on PORTB
  ora #LCD_EN   ; Prepare nibble with enable flag
  sta VIA_PORTB ; Put nibble on PORTB
  pla           ; Restore A to clear enable
  ora #LCD_RS   ; Set RS bit to write to data register
  sta VIA_PORTB ; Clear enable flag
  rts
lcd_put_char:
  jsr lcd_busy_wait
  pha                     ; Push original char to stack since we will corrupt into nibbles
  lsr                     ; Logical shift right 4-bits to get upper nibble
  lsr
  lsr
  lsr
  jsr lcd_put_char_nibble
  pla                     ; Pull original char from stack
  pha                     ; Push original char to stack since we will corrupt into nibbles
  and #$0F                ; Mask lower nibble
  jsr lcd_put_char_nibble
  pla                     ; Pull original char from stack
  rts

lcd_put_nibble:
  pha                       ; A will be modified to add ASCII offset
  and #$0F                  ; Mask to lower nibble
  cmp #$0A                  ; Compare with hex 'A'
  clc                       ; Clear the carry flag
  bne lcd_put_nibble_finish ; Check if difference is negative (A register < hex 'A')
  adc #('A'-'0')            ; Add offset between '0' character and 'A' character
lcd_put_nibble_finish:
  adc #'0'                  ; Add offset to '0' character
  jsr lcd_put_char
  pla
  rts

lcd_put_byte:
  pha ; A will be modified by shifting right
  lsr ; Logical shift right 4-bits
  lsr
  lsr
  lsr
  jsr lcd_put_nibble ; Put upper nibble
  pla
  jsr lcd_put_nibble ; Put lower nibble (lcd_put_nibble will mask $0F)
  rts

reset:
  sei                 ; Disable interrupts
  cld                 ; Clear decimal mode
  lda #$80             
  sta VIA_IER         ; Disable all VIA interrupts (set mde)
  lda #$00            
  ; Put VIA in safe state
  sta VIA_ACR         ; Clear ACR register
  sta VIA_PORTA       ; Clear PORTA
  sta VIA_PORTB       ; Clear PORTB
  ; Init LEDs on PORTA
  lda #$FF            
  sta VIA_DDRA        ; Set all PORTA pins as output
  ; Clear zero page and stack
  ldx #$FF            ; Start with max X offset (This will sweep starting at zp+255)
clear_zp_stack:
  sta   $00,x         ; Clear zero page with X offset
  sta $0100,x         ; Clear stack with X offset
  dex                 ; Decrement X
  cpx #$FF            ; Compare X to 0xFF to detect wrap around
  bne clear_zp_stack  ; If X has not wrapped around, continue in loop
  ; Init LCD
  jsr lcd_init        ; Initialize LCD
  ; Reset Complete
main:
  jmp halt



resb: ; Interrupts not expected, fall through to HALT Error
nmib:
halt_error:
  lda #$0E ; Output error code and halt
  jmp halt_code
halt:
  lda #$0D ; Output done code and halt
halt_code:
  sei           ; Disable any further interrupts
  sta VIA_PORTA ; Output code stored in A
halt_loop:
  jmp halt_loop ; Remain in infinite do-nothing loop

  .org STATIC_DATA_ADDRESS
string_test_msg: .asciiz "String Test"

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word resb