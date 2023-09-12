; "Hello, World program to verify ROM, RAM, VIA, and LCD are working as expected"


; Starting address of EEPROM
EEPROM_START_ADDRESS=$8000
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


LCD_RS       = $10 ; LCD Register Select on PORT B bit 4
LCD_RW       = $20 ; LCD Read/Write on PORT B bit 5
LCD_EN       = $40 ; LCD Enable on PORT B bit 6
LCD_BUSY     = $08 ; LCD Busy flag on PORT B bit 3



; Start of EEPROM
  .org EEPROM_START_ADDRESS

hello_world_string: .asciiz "Hello, World!"

resb:
nmib:
; Interrupts not expected, fall through to HALT
halt:
  jmp halt ; Remain in infinite do-nothing loop

lcd_busy_wait:
  pha
  lda #$70               ; Set lower nibble of PORTB a input
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
  lda #$7F               ; Restore lower nibble of PORTB as output
  sta VIA_DDRB
  pla
  rts

lcd_write_instruction_nibble:
  pha           ; Push A since it will be modified with enable flag
  sta VIA_PORTB ; Prepare nibbe on PORTB
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
  and $0F ; Mask the lower nibble
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
  and $0F                 ; Mask lower nibble
  jsr lcd_put_char_nibble
  pla                     ; Pull original char from stack
  rts

reset:
  sei                 ; Disable interrupts
  cld                 ; Clear decimal mode
  lda #$00            ; Load accumulator with empty byte
  ; Put VIA in safe state
  sta VIA_IER         ; Disable all interrupts
  sta VIA_PORTA       ; Clear PORTA
  sta VIA_PORTB       ; Clear PORTB
  ; Clear zero page and stack
  ldx #$FF            ; Start with max X offset (This will sweep starting at zp+255)
clear_zp_stack:
  sta   $00,x         ; Clear zero page with X offset
  sta $0100,x         ; Clear stack with X offset
  dex                 ; Decrement X
  cpx #$FF            ; Compare X to 0xFF to detect wrap around
  bne clear_zp_stack  ; If X has not wrapped around, continue in loop
  ;Init LCD
  lda #$7F
  sta VIA_DDRB        ; Set first 7-bits (4-data + EN + RW + RS) of PORTB pins as output
  lda #$28            ; Set LCD in 4-bit mode with 2 lines
  jsr lcd_write_instruction
  lda #$01            ; Clear LCD
  jsr lcd_write_instruction
  lda #$02            ; Return LCD to home
  jsr lcd_write_instruction
  lda #$06            ; Set LCD in incrementing mode
  jsr lcd_write_instruction
  lda #$0F            ; Turn on LCD with blinking cursor
  jsr lcd_write_instruction

  ; Reset Complete
main:
  ldx #$00      ; Init X as string index starting with index 0
print_hello_world_char:
  lda hello_world_string,x   ; Load next char
  beq halt_jmp               ; Halt when null-char is release
  jsr lcd_put_char           ; Call subroutin to put char to LCD
  inx                        ; Increment X to index next char
  jmp print_hello_world_char ; Handle new char
halt_jmp:
  jmp halt

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word resb