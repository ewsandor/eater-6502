; Implementation to run Conway's Game of Life simulations

  include eeprom/definitions.s

; Run-time variabes
CURR_WORLD_L    = $00   ; Pointer to active world buffer
CURR_WORLD_H    = $01
NEXT_WORLD_L    = $02   ; Pointer to next world buffer
NEXT_WORLD_H    = $03
ITERATING_BIT   = $04   ; Temporary variable for iterating 
REFRESH_TIME    = $05   ; Time of next refresh
NEIGHBOR_COUNT  = $06   ; Temporary variable to count neighboring cells
BOOLEAN_FLAGS   = $07   ; Temporary boolean flags
; Config Variables
SPAWN_WEIGHT    = $0600 ; Threshold to spawn cell
REFRESH_PERIOD  = $0601 ; Time between refreshes in seconds
GENERATIONS     = $0602 ; Number of generations to simulate
CONFIG_FLAGS    = $0603 ; Configuration flags
; World Buffers
WORLD_BUFFER_A  = $2000
WORLD_BUFFER_B  = $2100

; Constants
WORLD_WIDTH               = 8   ; 1/8th world width (each bit is one entry)
WORLD_HEIGHT              = 31  ; Number of world rows
WORLD_SIZE                = (WORLD_WIDTH * WORLD_HEIGHT) ; World size in bytes
DEFAULT_SPAWN_WEIGHT      = 32  ; 1/4 (32/128) bits set
DEFAULT_REFRESH_PERIOD    = 5   ; Refresh every 5 seconds
DEFAULT_GENERATIONS       = $08 ; Draw 8 generations
INFINITE_GENERATIONS_FLAG = $01 ; Inifite generation flag
SKIP_CENTER_BIT           = $01 ; Skip counting the center bit for this byte when counting neighbors

; Helper Routines
  .org $0700
set_defaults_main:
  lda #DEFAULT_SPAWN_WEIGHT
  sta SPAWN_WEIGHT
  lda #DEFAULT_REFRESH_PERIOD
  sta REFRESH_PERIOD
  lda #DEFAULT_GENERATIONS
  sta GENERATIONS
  lda #$00
  sta CONFIG_FLAGS
  jmp WOZMON_GETLINE

  .org $0720
clear_world_main:
  jsr clear_world
  jmp WOZMON_GETLINE

  .org $0730
random_spawn_main:
  jsr clear_world
  jsr random_spawn
  jmp WOZMON_GETLINE

  .org $0740
draw_world_main:
  lda #$00
  sta CURR_WORLD_L
  lda #$20
  sta CURR_WORLD_H
  jsr draw_world
  jmp WOZMON_GETLINE

; Internal subroutines
  .org $0750
draw_world:
  pha
  phx
  phy
  ldy #$00                ; Reset byte iterator
draw_world_loop_i:
; TODO need actual divide/remainder logic to use other widths
  tya                     ; Transfer Y to A
  and #$07                ; Mask lower 3 bits to check if multiple 8
  cmp #$00                ; Check if ends in 0
  bne draw_world_next_byte
draw_world_carriage_return:
  lda #$0D                ; Load CR character
  jsr PUT_CHAR            ; Output newline
draw_world_next_byte:
  lda #$80                ; Set interating bit
  sta ITERATING_BIT       ; Store in temporary variable
  ldx #$08                ; Iterate 8 bits using X
draw_world_loop_j:
  lda ITERATING_BIT       ; Load current iterating bit
  and (CURR_WORLD_L),y    ; Compare with world byte
  bne draw_world_put_cell
  lda #'.'                ; Print dead cell 
  bne draw_world_put_bit
draw_world_put_cell
  lda #'#'                ; Print live cell
draw_world_put_bit:
  jsr PUT_CHAR            ; Output cell
  lsr ITERATING_BIT       ; Shift iterating bit
  dex
  bne draw_world_loop_j
  iny
  cpy #WORLD_SIZE
  bne draw_world_loop_i
  ply
  plx
  pla
  rts


clear_world:
  ldx #$00
  lda #$00
clear_world_loop:
  sta WORLD_BUFFER_A,x
  sta WORLD_BUFFER_B,x
  inx
  cpx #WORLD_SIZE
  bne clear_world_loop
  rts
  
random_spawn:
  ldx #$00              ; Reset byte iterator
random_spawn_loop_i:
  lda #$01              ; Set interating bit
  sta ITERATING_BIT     ; Store in temporary variable
  ldy #$08              ; Iterate 8 bits using Y
random_spawn_loop_j:
  jsr GET_RANDOM_NUMBER
  and #$7F              ; Mask random number to be positive (0-127)
  cmp SPAWN_WEIGHT
  bpl random_spawn_next ; If random number - weight is positive, do not spawn
  lda ITERATING_BIT     ; Load iterating bit from memory
  ora WORLD_BUFFER_A,x  ; OR-in current mask in world buffer-A byte
  sta WORLD_BUFFER_A,x  ; Store new world byte in buffer A
  sta WORLD_BUFFER_B,x  ; Store new world byte in buffer B
random_spawn_next:
  asl ITERATING_BIT     ; Shift iterating bit
  dey
  bne random_spawn_loop_j
  inx                   ; Increment byte iterator
  cpx #WORLD_SIZE       ; Check if in world bounds
  bne random_spawn_loop_i
  rts

swap_world_buffer:
  pha
  phx
  ; Swap active buffers
  lda NEXT_WORLD_H ; Retrieve next high-byte
  tax              ; Hold next high-byte in X
  lda CURR_WORLD_H ; Retrieve current high-byte
  sta NEXT_WORLD_H ; Store current high-byte as next high-byte
  txa              ; Retrieve stored next high-byte
  sta CURR_WORLD_H ; Store saved next high-byte as current byte
  plx
  pla
  rts

  .org $0800
main:
  ; Init current world with 'Buffer A' address and next world with 'Buffer B'
  lda #$00
  sta CURR_WORLD_L
  lda #$20
  sta CURR_WORLD_H
  lda #$00
  sta NEXT_WORLD_L
  lda #$21
  sta NEXT_WORLD_H
  ; Init refresh time
  lda SYSTIME_0
  clc
  adc REFRESH_PERIOD ; Add period to current time
  sta REFRESH_TIME   ; Use sum as timestamp of next refresh
  ; Initialze generation counter
  ldy #$00 
  ; Start main loop
main_loop:
  ; Clear the output
  ldx #(WORLD_HEIGHT)
  lda #$0D
draw_clear_loop:
  jsr PUT_CHAR
  dex
  bne draw_clear_loop
  ; Output generation
  lda #'G'
  jsr PUT_CHAR
  tya               ; Y is counting generation, transfer to A
  jsr WOZMON_PRBYTE ; TODO formalize 'native' put_byte call (avoid extra jsr at WOZMON_ECHO)
  ; Draw current world
  jsr draw_world
  jsr next_gen
  jsr swap_world_buffer
  ; Increment genration counter
  iny
  lda CONFIG_FLAGS
  and #INFINITE_GENERATIONS_FLAG
  bne refresh_time_wait ; Always contine loop if infinite mode
  cpy GENERATIONS       ; Compare if max generation is reached
  beq exit              ; Exit when max generations reached
  ; Wait for refresh time
refresh_time_wait:
  lda REFRESH_TIME
  cmp SYSTIME_0
  bpl refresh_time_wait
  clc
  adc REFRESH_PERIOD
  sta REFRESH_TIME
  jmp main_loop
exit:
  ; CR to move to next line
  lda #$0D
  jsr PUT_CHAR
  ; Output 'D' to note progrm is done
  lda #'D'
  jsr PUT_CHAR
  ; Return to WOZMON
  jmp WOZMON_GETLINE

; Main program miscelaneous subroutines
  .org $0880
next_gen:
  pha
  phx
  phy
  ldy #$00                ; Reset byte iterator
next_gen_loop_i:
  lda #$80                ; Set interating bit
  sta ITERATING_BIT       ; Store in temporary variable
  ldx #$08                ; Iterate 8 bits using X
next_gen_loop_j:
  lda #$00
  sta NEIGHBOR_COUNT      ; Reset neighbor counter
  ; Check bit to the left
  lda ITERATING_BIT       ; Load current iterating bit
  cmp #$80                ; Check if MSB is being checked
  bne next_gen_left_bit_same_byte
  tya
  beq next_gen_center_bit ; Continue to centr bit if Y is zero
  dey                     ; Fetch previous world byte
  lda (CURR_WORLD_L),y
  iny
  and #$01                ; Check if LSB is set
  beq next_gen_center_bit ; Continue to center bit if not zero
  inc NEIGHBOR_COUNT
  jmp next_gen_center_bit
  ; Get bit from prevous byte
next_gen_left_bit_same_byte:
  asl                      ; Shift iterating bit left
  and (CURR_WORLD_L),y     ; Compare to current bit
  beq next_gen_center_bit  ; Continue to center bit if not zero
  ; bit-to-left is set, increment neighbor count
  inc NEIGHBOR_COUNT
next_gen_center_bit:
  lda BOOLEAN_FLAGS
  and SKIP_CENTER_BIT
  bne next_gen_right_bit
  lda ITERATING_BIT
  and (CURR_WORLD_L),y     ; Compare to current bit
  beq next_gen_right_bit   ; Continue to center bit if not zero
  inc NEIGHBOR_COUNT       ; center bit is set, increment neighbor count
next_gen_right_bit:
  ; Check bit to the left
  lda ITERATING_BIT        ; Load current iterating bit
  cmp #$01                 ; Check if MSB is being checked
  bne next_gen_right_bit_same_byte
  cpy #(WORLD_SIZE-1)      ; Check if last byte in world
  beq next_gen_manage_fate
  iny
  lda (CURR_WORLD_L),y     ; Fetch next byte
  dey
  and #$80                 ; Check if MSB is set
  beq next_gen_manage_fate ; Continue if bit isn't set
  inc NEIGHBOR_COUNT       ; Increment neighbor count
  jmp next_gen_manage_fate
next_gen_right_bit_same_byte:
  lsr                      ; Shift iterating bit left
  and (CURR_WORLD_L),y     ; Compare to current bit
  beq next_gen_manage_fate ; Continue to center bit if not zero
  ; bit-to-right is set, increment neighbor count
  inc NEIGHBOR_COUNT
next_gen_manage_fate;
  ; TODO manage cells fate based on neighbor count
  ; sta (NEXT_WORLD_L),y   ; TODO update next world bit
next_gen_next_bit:
  lsr ITERATING_BIT        ; Shift iterating bit
  dex
  bne next_gen_loop_j
  iny
  cpy #WORLD_SIZE
  bne next_gen_loop_i
  ply
  plx
  pla
  rts

