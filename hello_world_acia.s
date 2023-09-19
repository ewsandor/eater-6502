; Simple program to count time since bootup to verify interrupts


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
VIA_IER_SET  = $80 ; IER set mode

; LCD Constants
LCD_RS        = $10 ; LCD Register Select on PORT B bit 4
LCD_RW        = $20 ; LCD Read/Write on PORT B bit 5
LCD_EN        = $40 ; LCD Enable on PORT B bit 6
LCD_BUSY      = $08 ; LCD Busy flag on PORT B bit 3
LCD_WRITE_DDR = $7F ; PORTB DDR mask when writing
LCD_READ_DDR  = $70 ; PORTB DDR mask when writing



; 6551 ACIA Register
ACIA_DATA        = $5000 ; Write transmit data/Read receiver data
ACIA_STATUS      = $5001 ; Status register
ACIA_COMMAND     = $5002 ; Command register
ACIA_CONTROL     = $5003 ; Control register
; 6551 ACIA Constants
ACIA_BAUD_115200 = $00
ACIA_BAUD_9600   = $0E
ACIA_BAUD_19200  = $0F
ACIA_WL_8_BITS   = $00 ; Word length
ACIA_WL_7_BITS   = $20
ACIA_WL_6_BITS   = $40
ACIA_WL_5_BITS   = $60
ACIA_CLOCK_EXT   = $00 ; Use external baud clock
ACIA_CLOCK_BAUD  = $10 ; Use baud clock generator
ACIA_STOP_BITS_1 = $00
ACIA_STOP_BITS_2 = $80
ACIA_DTR_ENABLE  = $01
ACIA_RTSB_HIGH   = $00
ACIA_RTSB_LOW    = $08
ACIA_ECHO        = $10



; System Variables
SYSTIME_F     = $F7 ; Frantional-seconds (1/256) portion of SYSTIME
SYSTIME_0     = $F8 ; First (lowest) byte of SYSTIME in seconds
SYSTIME_1     = $F9 ; Second byte of SYSTIME in seconds
SYSTIME_2     = $FA ; Third byte of SYSTIME in seconds
SYSTIME_3     = $FB ; Fourth (highest) byte of SYSTIME in seconds
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
  lda #$06                  ; Set LCD in incrementing mode
  jsr lcd_write_instruction
  lda #$0C                  ; Turn on LCD without cursor
; lda #$0E                  ; Turn on LCD with static cursor
; lda #$0F                  ; Turn on LCD with blinking cursor
  jsr lcd_write_instruction
  jsr lcd_clear             ; Clear LCD
  jsr lcd_home              ; Return LCD cursor to home
  rts


delay_ticks:           ; Blocking delay (tick count set in DELAY_TICKS_L/H)
  pha
  lda DELAY_TICKS_L    ; Load lower-byte from memory
  sta VIA_T2CL         ; Write Timer-2 counter's lower-byte
  lda DELAY_TICKS_H    ; Load upper-byte from memory
  sta VIA_T2CH         ; Write Timer-2 counter's upper-byte
delay_ticks_wait:
  lda VIA_IFR          ; Read VIA interrupt flag register
  and #VIA_IFR_T2      ; Check if Timer-2 IFR flag is set
  beq delay_ticks_wait ; Loop while interrupt flag is not set (previous 'and' instruciton will result in zero)
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
  sta VIA_PORTB ; Prepare nibble on PORTB
  ora #LCD_EN   ; Prepare nibble with enable flag
  sta VIA_PORTB ; Put nibble on PORTB
  and #~(LCD_EN) ; Clear enable flag from A
  sta VIA_PORTB  ; Clear enable flag
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

lcd_clear:
  pha
  lda #$01                  ; Clear LCD
  jsr lcd_write_instruction
  pla
  rts
lcd_home:
  pha
  lda #$02                  ; Return LCD to home
  jsr lcd_write_instruction
  pla
  rts


lcd_put_char_nibble:
  ora #LCD_RS             ; Set RS bit to write to data register
  sta VIA_PORTB           ; Prepare nibbe on PORTB
  ora #LCD_EN             ; Prepare nibble with enable flag
  sta VIA_PORTB           ; Put nibble on PORTB
  and #~(LCD_EN | LCD_RS) ; Clear enable flag and RS
  sta VIA_PORTB           ; Clear enable flag and RS from PORTB
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
  bmi lcd_put_nibble_finish ; Check if difference is negative (A register < hex 'A')
  adc #('A'-'0'-$A)         ; Add offset between '0' character and 'A' character
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

acia_put_char:
  pha
  sta ACIA_DATA
  ; WDC 6551 TX register has a hardware bug.  Wait 1.042ms ($0412) for 9600 baud character
  lda #$12
  sta DELAY_TICKS_L
  lda #$04
  sta DELAY_TICKS_H
  jsr delay_ticks
  pla
  rts

; Reset Operations
reset:
  sei                             ; Disable interrupts
  cld                             ; Clear decimal mode
  ; Init LEDs on PORTA
  lda #$FF
  sta VIA_DDRA                    ; Set all PORTA pins as output
  ; Configure VIA
  ;   Timer-1 continous mode on ACR (no PB output)
  ;   Timer-2 Timed Interrupt (no PB output)
  ;   Shift-Register Disabled
  ;   PORTA/PORTB latching disabled
  lda #$40
  sta VIA_ACR
  lda #(VIA_IER_SET | VIA_IFR_T1) ; Configure VIA Timer-1 interrupt
  sta VIA_IER
  lda #$00
  sta VIA_PORTA                   ; Clear PORTA
  sta VIA_PORTB                   ; Clear PORTB
 ; Clear zero page and stack
  ldx #$FF                        ; Start with max X offset (This will sweep starting at zp+255)
clear_zp_stack_loop:
  sta   $00,x                     ; Clear zero page with X offset
  sta $0100,x                     ; Clear stack with X offset
  dex                             ; Decrement X
  cpx #$FF                        ; Compare X to 0xFF to detect wrap around
  bne clear_zp_stack_loop         ; If X has not wrapped around, continue in loop
  ; Init LCD
  jsr lcd_init                    ; Initialize LCD
  ; Start VIA Timer-1 for 1/256 seconds ($0F42 ticks)
  lda #$40                        ; Interrupt triggers after N+2 clock cycles.  Fill lower byte as $40 instead of $42 to account for '+2'
  sta VIA_T1CL                    ; Write Timer-1 counter's lower-byte
  lda #$0F
  sta VIA_T1CH                    ; Write Timer-1 counter's upper-byte.  This starts Timer-1 running
  ; Init ACIA Peripheral
  sta ACIA_STATUS                 ; Write to chip to force a soft reset
  lda #(ACIA_STOP_BITS_1 | ACIA_WL_8_BITS | ACIA_CLOCK_BAUD | ACIA_BAUD_9600) 
  sta ACIA_CONTROL                ; Configure 9600-8-N-1 serial on the Control regiester
  lda #(ACIA_RTSB_LOW | ACIA_DTR_ENABLE)
  sta ACIA_COMMAND                ; Set Data Terminal Ready on the command register to enable receive interrupts
  ; Enable interrupts
  cli
  ; Reset Complete

; Start of Main Program
main:
  ldx #$00      ; Init X as string index starting with index 0
print_hello_world_char:
  lda hello_world_string,x   ; Load next char
  beq halt                   ; Halt when null-char is release
  jsr lcd_put_char           ; Call subroutine to output char to LCD
  jsr acia_put_char          ; Call subroutine to output char to ACIA
  inx                        ; Increment X to index next char
  jmp print_hello_world_char ; Handle new char

irqb: ; Interrupt Handler
  pha
  lda VIA_IFR          ; Read VIA interrupt flag register
  and #VIA_IFR_T1      ; Check if Timer-1 IFR flag is set
  bne timer_1_irq      ; Branch to timer 1 IRQ handler if Timer-1 bit is set
  jmp halt_error       ; Only timer interrupt should be enabled.  Halt with error if any other interrupt is triggered

timer_1_irq:
  lda VIA_T1CL         ; Clear T1 interrupt flag by reading 'T1C-L'
  ; Increment SYSTIME data
  inc SYSTIME_F
  bne irqb_exit ; If 0, rollover occurred, increment next byte
  inc SYSTIME_0
  bne irqb_exit
  inc SYSTIME_1
  bne irqb_exit
  inc SYSTIME_2
  bne irqb_exit
  inc SYSTIME_3

irqb_exit:
  pla
  rti

nmib: ; Non-Maskable Interrupts not expected, fall through to HALT Error
halt_error:
  lda #$E0 ; Output error code and halt
  jmp halt_code
halt:
  lda #$D0 ; Output done code and halt
halt_code:
  sei           ; Disable any further interrupts
  sta VIA_PORTA ; Output code stored in A
halt_loop:
  jmp halt_loop ; Remain in infinite do-nothing loop

  .org STATIC_DATA_ADDRESS
hello_world_string: .asciiz "Hello, World!"

; Vector Table
  .org NMIB_VECTOR
  .word nmib
  .org RESB_VECTOR
  .word reset
  .org IRQB_VECTOR
  .word irqb