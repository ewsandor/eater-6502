; General System Functions

.segment "IRQ"
; Interrupt Handler
irqb: 
  pha
  lda VIA_IFR          ; Read VIA interrupt flag register
  bmi via_irq          ; Jump to sub-handler if 'any' flag set
  lda ACIA_STATUS      ; Read ACIA status flag
  bmi acia_irq         ; Jump to sub-handler if 'IRQ' flag is set
  jmp irq_exit         ; For some reason stray IRQ is called.  Need to debug further
;  jmp halt_error       ; Halt with error code if interrupt was not processed
acia_irq:
  pha                   ; Save status register (cleared by 'and')
  and #(ACIA_STATUS_OVRN | ACIA_STATUS_FE | ACIA_STATUS_PE) ; Check for receiver errors
  bne acia_error_irq    ; Branch to error if non-zero
  pla                   ; Restore status register (undo 'and')
  and #ACIA_STATUS_RDRF ; Check if receiver data register full flag is set
  bne acia_rdrf_irq     ; Jump to receiver data register full IRQ handler if non-zero
;  jmp halt_error       ; Halt with error if no interrup was processed
  jmp irq_exit          ; For some reason IRQ is called.  Need to debug this further...
acia_error_irq:
  ora #$E0              ; Keep error flags in lower nibble
  jmp halt_code
acia_rdrf_irq:
  phx                    ; Save X register
  ldx INPUT_BUFFER_W     ; Load the next input buffer write index
  lda ACIA_DATA          ; Load the data register
  sta INPUT_BUFFER,x     ; Store read characte in input buffer
  inx                    ; Move to next input buffer index
  lda #$00               ; Prepare null-character
  sta INPUT_BUFFER,x     ; Put null character in next write index (Keep input-buffer a null terminated string)
  stx INPUT_BUFFER_W     ; Update next write index
  cpx INPUT_BUFFER_R     ; Compare to to the read index
  bne acia_rdrf_irq_exit ; Skip to irq exit as long as read index != write inded (overflow)
  jmp halt_error         ; Halt with error on overflow
acia_rdrf_irq_exit:
  plx                    ; Restore X register
  jmp irq_exit
via_irq:
  and #VIA_IFR_T1      ; Check if Timer-1 IFR flag is set
  bne timer_1_irq      ; Branch to timer 1 IRQ handler if Timer-1 bit is set
  jmp halt_error       ; Only timer interrupt should be enabled.  Halt with error if any other interrupt is triggered
timer_1_irq:
  lda VIA_T1CL         ; Clear T1 interrupt flag by reading 'T1C-L'
  ; Increment SYSTIME data
  inc SYSTIME_F
  bne irq_exit ; If 0, rollover occurred, increment next byte
  inc SYSTIME_0
  bne irq_exit
  inc SYSTIME_1
  bne irq_exit
  inc SYSTIME_2
  bne irq_exit
  inc SYSTIME_3
irq_exit:
  pla
  rti

; Reset Operations
.segment "RESET"
reset:
.export RESET := reset
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
  sta INPUT_BUFFER_R              ; Reset input buffer read index
  sta INPUT_BUFFER_W              ; Reset input buffer write index
 ; Initialize zero page and stack
  ldx #$FF                        ; Load X with $FF to initialize SP
  txs                             ; Initialize stack with max address $01FF
  inx                             ; Increment X to set index $00
clear_zp_stack_loop:
  sta          $00,x              ; Clear zero page with X offset
  sta        $0100,x              ; Clear stack with X offset
  sta INPUT_BUFFER,x              ; Clear input buffer with x offset
  sta    WOZMON_IN,x              ; Clear WOZMON Input buffer
  inx                             ; Increment X
  bne clear_zp_stack_loop         ; If X has not wrapped around (not zero), continue in loop
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
  jmp wozmon 

.segment "HALT"
nmib: ; Non-Maskable Interrupts not expected, fall through to HALT Error
halt_error:
.export HALT_ERROR := halt_error
  lda #$E0 ; Output error code and halt
  bne halt_code
halt:
.export HALT := halt
  lda #$D0 ; Output done code and halt
  bne halt_code
halt_code:
.export HALT_CODE := halt_code
  sei           ; Disable any further interrupts
  sta VIA_PORTA ; Output code stored in A
halt_loop:
  jmp halt_loop ; Remain in infinite do-nothing loop

.CODE
  ; System call to put character to both LCD and ACIA
put_char:
.export PUT_CHAR := put_char
  pha
  sta ACIA_DATA
  ; WDC 6551 TX register has a hardware bug.  Wait 1.042ms ($0412) for 9600 baud character
  lda #$12
  sta VIA_T2CL
  lda #$04
  sta VIA_T2CH
  ; Call subroutine to output char to LCD while waiting for ACIA delay
  pla
  jsr lcd_put_char
  pha
  ; Wait for end of delay
put_char_delay_loop:
  lda VIA_IFR               ; Read VIA interrupt flag register
  and #VIA_IFR_T2           ; Check if Timer-2 IFR flag is set
  beq put_char_delay_loop   ; Loop while interrupt flag is not set (previous 'and' instruciton will result in zero)
  lda VIA_T2CL              ; Clear interrupt flag
  pla
  rts

put_string:
.export PUT_STRING := put_string
  pha
  lda PUT_STRING_L
  pha
  lda PUT_STRING_H
  pha
put_string_loop:
  lda (PUT_STRING_L)
  beq put_string_return
  jsr put_char
  inc PUT_STRING_L
  bne put_string_loop
  inc PUT_STRING_H
  jmp put_string_loop
put_string_return:
  pla
  sta PUT_STRING_H
  pla
  sta PUT_STRING_L
  pla
  rts

memcpy:
.export MEMCPY := memcpy
  pha
  phy
  lda SYSTEM_TEMP_0
  pha
  sty SYSTEM_TEMP_0
  ldy #$00
memcpy_loop:
  lda (SYS_MEMCPY_SRC_L),y
  sta (SYS_MEMCPY_DEST_L),y
  iny
  cpy SYSTEM_TEMP_0
  bne memcpy_loop
memcpy_return:
  pla
  sta SYSTEM_TEMP_0
  ply
  pla
  rts


; Borrowing Psuedo-random number generator from "Super Mario World" 
;    Thanks to 'Retro Game Mechanics Explained' (https://www.youtube.com/watch?v=q15yNrJHOak)
get_random_number:
.export GET_RANDOM_NUMBER := get_random_number
  phy
  ldy #$01
  jsr get_random_number_tick
  dey
  jsr get_random_number_tick
  ply
  rts



  ; Miscellaneous System Subroutines
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
; lda #$0C                  ; Turn on LCD without cursor
; lda #$0E                  ; Turn on LCD with static cursor
  lda #$0F                  ; Turn on LCD with blinking cursor
  jsr lcd_write_instruction
  jsr lcd_clear             ; Clear LCD
  jsr lcd_home              ; Return LCD cursor to home
  rts


delay_ticks:           ; Blocking delay (tick count set in DELAY_TICKS_L/H)
.export DELAY_TICKS := delay_ticks
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
  and #<(~(LCD_EN)) ; Clear enable flag from A
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

lcd_newline:
  pha
  lda LCD_STATE_SYS
  eor #LCD_STATE_SYS_LINE ; Toggle line index
  sta LCD_STATE_SYS
  and #LCD_STATE_SYS_LINE ; Check if on line index 0
  bne lcd_newline_1
  lda #$80                ; Put cursor at position 0
  jmp lcd_newline_apply
lcd_newline_1:
  lda #$A8                ; Put cursor at position 40
lcd_newline_apply:
  jsr lcd_write_instruction
  pla
  rts
lcd_backspace:
  pha
  lda #$04                  ; Set LCD in decrementing mode
  jsr lcd_write_instruction
  lda #' '                  ; Write space and decrement
  jsr lcd_put_char
  lda #$06                  ; Set LCD in incrementing mode
  jsr lcd_write_instruction
  pla
  rts

lcd_put_char_nibble:
  ora #LCD_RS             ; Set RS bit to write to data register
  sta VIA_PORTB           ; Prepare nibbe on PORTB
  ora #LCD_EN             ; Prepare nibble with enable flag
  sta VIA_PORTB           ; Put nibble on PORTB
  and #<(~(LCD_EN | LCD_RS)) ; Clear enable flag and RS
  sta VIA_PORTB           ; Clear enable flag and RS from PORTB
  rts
lcd_put_char:
  jsr lcd_busy_wait
  pha                     ; Push original char to stack since we will corrupt A
  cmp #$0D                ; CR?
  beq lcd_put_char_cr
  cmp #$08                ; Backspace?
  beq lcd_put_char_backspace
  phx
  tax
  lda lcd_char_mapping,x
  plx
  pha                     ; Push mapped char into nibbles
  lsr                     ; Logical shift right 4-bits to get upper nibble
  lsr
  lsr
  lsr
  jsr lcd_put_char_nibble
  pla                     ; Pull mapped char from stack
  and #$0F                ; Mask lower nibble
  jsr lcd_put_char_nibble
  pla                     ; Pull original char from stack
  rts
lcd_put_char_cr:
  jsr lcd_newline
  pla
  rts
lcd_put_char_backspace:
  jsr lcd_backspace
  pla
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

; Blocking system call to get next char from input buffer
get_char:
.export GET_CHAR := get_char
  phx
  ldx INPUT_BUFFER_R      ; Load next read index
get_char_wait_input:
  cpx INPUT_BUFFER_W      ; Compare to next write index
  beq get_char_wait_input ; Loop until write index != read index
  lda INPUT_BUFFER, x     ; Read next char from input buffer
  plx
  inc INPUT_BUFFER_R      ; Increment read buffer index
  rts

get_random_number_tick:
  lda SYS_RNG_SEED_L
  asl
  asl
  sec
  adc SYS_RNG_SEED_L
  sta SYS_RNG_SEED_L
  asl SYS_RNG_SEED_H
  lda #$20
  bit SYS_RNG_SEED_H
  bcc get_random_number_tick_label1
  beq get_random_number_tick_label3
  bne get_random_number_tick_label2
get_random_number_tick_label1:
  bne get_random_number_tick_label3
get_random_number_tick_label2:
  inc SYS_RNG_SEED_H
get_random_number_tick_label3:
  lda SYS_RNG_SEED_H
  eor SYS_RNG_SEED_L
  sta SYS_RNG_OUTPUT_L,y
  rts

; Copy SYS_MEMCPY_SIZE bytes from SYS_MEMCPY_SRC to SYS_MEMCPY_DEST
memcpy_large:
  pha
  clc ; Clear carry flag
  ; Prepare working variable for sorce & destination addresses as well as size
  ; Source
  lda SYS_MEMCPY_SRC_L
  sta SYSTEM_TEMP_0
  lda SYS_MEMCPY_SRC_H 
  sta SYSTEM_TEMP_1
  ; Destination
  lda SYS_MEMCPY_DEST_L
  sta SYSTEM_TEMP_2
  lda SYS_MEMCPY_DEST_H
  sta SYSTEM_TEMP_3
  ; Size
  lda SYS_MEMCPY_SIZE_L
  sta SYSTEM_TEMP_4
  lda SYS_MEMCPY_SIZE_H
  sta SYSTEM_TEMP_5
  lda SYSTEM_TEMP_4      ; Check low-byte of size counter
  bne memcpy_large_loop        ; Branch to copy if not zero
  lda SYSTEM_TEMP_5      ; Check high-byte of size counter
  beq memcpy_large_ret         ; Branch to return if both high/low bites of counter are zero
memcpy_large_loop:
  lda (SYSTEM_TEMP_0)    ; Load indirect address of source poiner
  sta (SYSTEM_TEMP_2)    ; Store indirect address of destination poiner
; Increment source pointer
  inc SYSTEM_TEMP_0
  bne memcpy_large_inc_dest    ; Continue to destionation if no-wrap around occured
  inc SYSTEM_TEMP_1
; Increment destination pointer
memcpy_large_inc_dest:
  inc SYSTEM_TEMP_2
  bne memcpy_large_dec_counter ; Continue to destionation if no-wrap around occured
  inc SYSTEM_TEMP_3
memcpy_large_dec_counter:
  dec SYSTEM_TEMP_4      ; Decrement low byte of size counter
  cmp #$FF               ; Check for wrap-around
  bne memcpy_large_loop        ; Continue if no wrap-around occured
  dec SYSTEM_TEMP_5 
  cmp #$FF
  bne memcpy_large_loop
memcpy_large_ret:
  pla
  rts