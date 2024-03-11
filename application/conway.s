; Implementation to run Conway's Game of Life simulations

.include "bios_syscall.inc"

; Run-time variabes
.segment "ZPDATA"
CURR_WORLD:
  .res 2
CURR_WORLD_L      = <CURR_WORLD   ; Pointer to active world buffer
CURR_WORLD_H      = >CURR_WORLD
NEXT_WORLD:
  .res 2
NEXT_WORLD_L      = <NEXT_WORLD   ; Pointer to next world buffer
NEXT_WORLD_H      = >NEXT_WORLD

ITERATING_BIT:   ; Temporary variable for iterating 
  .res 1
REFRESH_TIME:    ; Time of next refresh
  .res 1
NEIGHBOR_COUNT:  ; Temporary variable to count neighboring cells
  .res 1
BOOLEAN_FLAGS:   ; Temporary boolean flags
  .res 1

CELL_POPULATION:
  .res 2
CELL_POPULATION_L = <CELL_POPULATION   ; Counter for live cell population
CELL_POPULATION_H = >CELL_POPULATION   ; Counter for live cell population
; Config Variables

.data
SPAWN_WEIGHT:   ; Threshold to spawn cell
  .res 1
REFRESH_PERIOD: ; Time between refreshes in seconds
  .res 1
GENERATIONS:    ; Number of generations to simulate
  .res 1
CONFIG_FLAGS:   ; Configuration flags
  .res 1

.bss
; World Buffers
WORLD_BUFFER_A:
  .res $0100
WORLD_BUFFER_B:
  .res $0100

; Constants
WORLD_WIDTH               = 8    ; 1/8th world width (each bit is one entry)
WORLD_HEIGHT              = 31   ; Number of world rows
WORLD_SIZE                = (WORLD_WIDTH * WORLD_HEIGHT) ; World size in bytes
DEFAULT_SPAWN_WEIGHT      = $7F  ; ~1/2 (127/255) bits set
DEFAULT_REFRESH_PERIOD    = 5    ; Refresh every 5 seconds
DEFAULT_GENERATIONS       = $08  ; Draw 8 generations
INFINITE_GENERATIONS_FLAG = $01  ; Inifite generation flag
SKIP_CENTER_BIT           = $01  ; Skip counting the center bit for this byte when counting neighbors

; Helper Routines
.code
set_defaults_main:
.export SET_DEFAULTS_MAIN := set_defaults_main
  lda #DEFAULT_SPAWN_WEIGHT
  sta SPAWN_WEIGHT
  lda #DEFAULT_REFRESH_PERIOD
  sta REFRESH_PERIOD
  lda #DEFAULT_GENERATIONS
  sta GENERATIONS
  lda #$00
  sta CONFIG_FLAGS
  ; Init current world with 'Buffer A' address and next world with 'Buffer B'
  lda #$00
  sta CURR_WORLD_L
  sta NEXT_WORLD_L
  lda #$20
  sta CURR_WORLD_H
  lda #$21
  sta NEXT_WORLD_H
  lda SYSTIME_F
  sta SYS_RNG_SEED_L
  lda SYSTIME_0
  sta SYS_RNG_SEED_H
  jmp WOZMON_GETLINE

clear_world_main:
.export CLEAR_WORLD_MAIN := clear_world_main
  jsr clear_world
  jmp WOZMON_GETLINE

random_spawn_main:
.export RANDOM_SPAWN_MAIN := random_spawn_main
  jsr clear_world
  jsr random_spawn
  jmp WOZMON_GETLINE

draw_world_main:
.export DRAW_WORLD_MAIN := draw_world_main
  jsr draw_world
  jmp WOZMON_GETLINE

copy_world_main:
.export COPY_WORLD_MAIN := copy_world_main
  lda CURR_WORLD_L
  sta SYS_MEMCPY_SRC_L
  lda CURR_WORLD_H
  sta SYS_MEMCPY_SRC_H
  lda NEXT_WORLD_L
  sta SYS_MEMCPY_DEST_L
  lda NEXT_WORLD_H
  sta SYS_MEMCPY_DEST_H
  ldy #WORLD_SIZE
  ldx MEMCPY
  jsr SYSCALL
  jmp WOZMON_GETLINE

.rodata
  .asciiz "Population: "
  .asciiz "Done."
  .asciiz "Generation: "

.code
main:
.export MAIN:=main
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
  ldx #(WORLD_HEIGHT+2)
  lda #$0D
draw_clear_loop:
  phx
  ldx PUT_CHAR
  jsr SYSCALL
  plx
  dex
  bne draw_clear_loop
  ; Output generation string
  lda #$F0
  sta PUT_STRING_L
  lda #$07
  sta PUT_STRING_H
  phx
  ldx PUT_STRING
  jsr SYSCALL 
  plx
  tya               ; Y is counting generation, transfer to A
  jsr WOZMON_PRBYTE ; TODO formalize 'native' put_byte call (avoid extra jsr at WOZMON_ECHO)
  ; Draw current world
  jsr draw_world
  jsr next_gen
  jsr swap_world_buffer
  ; Increment generation counter
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
  phx
  ldx PUT_CHAR
  jsr SYSCALL
  ; Output generation string
  lda #$E8
  sta PUT_STRING_L
  lda #$07
  sta PUT_STRING_H
  ldx PUT_STRING
  jsr SYSCALL
  plx
  ; Return to WOZMON
  jmp WOZMON_GETLINE

; Main program miscelaneous subroutines
next_gen:
  pha
  phx
  phy
  ldy #$00                 ; Reset byte iterator
next_gen_loop_i:
  lda #$00                 ; Clear byte in next generation's world
  sta (NEXT_WORLD_L),y
  lda #$80                 ; Set interating bit
  sta ITERATING_BIT        ; Store in temporary variable
  ldx #$08                 ; Iterate 8 bits using X
next_gen_loop_j:
  lda #$00
  sta NEIGHBOR_COUNT       ; Reset neighbor counter
  ; Check current row neighbors
  lda BOOLEAN_FLAGS
  pha                      ; Store previous set of flags
  ora #SKIP_CENTER_BIT     ; Set flag to skip center bit
  sta BOOLEAN_FLAGS
  jsr next_gen_count_byte_neighbors
  pla                      ; Restore previous set of flags
  sta BOOLEAN_FLAGS
  tya
  sec
  sbc #WORLD_WIDTH         ; Subtract one width to go to previous row
  bcc next_gen_next_row    ; Continue if carry flag was cleared
  phy
  tay
  jsr next_gen_count_byte_neighbors
  ply
next_gen_next_row:
  tya
  clc
  adc #WORLD_WIDTH         ; Add one width to go to next row
  cmp #WORLD_SIZE
  bcs next_gen_manage_fate ; Continue if next row is beyond world size
  phy
  tay
  jsr next_gen_count_byte_neighbors
  ply
next_gen_manage_fate:
  ; Check if cell should respawn in new world
  lda NEIGHBOR_COUNT
  cmp #02                  ; Check if exactly 2 neighbors.
  beq next_gen_clone_cell  ; Any live cell with two or three live neighbours lives on to the next generation.
  cmp #03                  ; Check if exactly 3 neighbors.  
  beq next_gen_spawn_cell  ; Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
  ; Any live cell with fewer than two live neighbours dies, as if by underpopulation.
  ; Any live cell with more than three live neighbours dies, as if by overpopulation.
  jmp next_gen_next_bit
next_gen_clone_cell:
  ; Check if cell exists in current world
  lda ITERATING_BIT
  and (CURR_WORLD_L),y 
  beq next_gen_next_bit    ; If cell is dead, do not respawn
next_gen_spawn_cell:
  lda ITERATING_BIT
  ora (NEXT_WORLD_L),y     ; OR-in iterating bit
  sta (NEXT_WORLD_L),y     ; Store updated byte 
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

next_gen_count_byte_neighbors:
  ; Check bit to the left
  lda ITERATING_BIT       ; Load current iterating bit
  cmp #$80                ; Check if MSB is being checked
  bne next_gen_left_bit_same_byte
  ; Check if first byte of row (byte%8==0)
  tya
  and #$07
  cmp #$00
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
  and #SKIP_CENTER_BIT
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
  ; Check if next byte is in next row (byte%8==7)
  tya 
  and #$07                 
  cmp #$07
  beq next_gen_count_byte_neighbors_exit
  iny
  lda (CURR_WORLD_L),y     ; Fetch next byte
  dey
  and #$80                 ; Check if MSB is set
  beq next_gen_count_byte_neighbors_exit ; Continue if bit isn't set
  inc NEIGHBOR_COUNT       ; Increment neighbor count
  jmp next_gen_count_byte_neighbors_exit
next_gen_right_bit_same_byte:
  lsr                      ; Shift iterating bit left
  and (CURR_WORLD_L),y     ; Compare to current bit
  beq next_gen_count_byte_neighbors_exit ; Continue to center bit if not zero
  ; bit-to-right is set, increment neighbor count
  inc NEIGHBOR_COUNT
next_gen_count_byte_neighbors_exit:
  rts
; Internal subroutines
draw_world:
  pha
  phx
  phy
  lda #$00                ; Reset population counter
  sta CELL_POPULATION_L
  sta CELL_POPULATION_H
  ldy #$00                ; Reset byte iterator
draw_world_loop_i:
; TODO need actual divide/remainder logic to use other widths
  tya                     ; Transfer Y to A
  and #$07                ; Mask lower 3 bits to check if multiple 8
  cmp #$00                ; Check if ends in 0
  bne draw_world_next_byte
draw_world_carriage_return:
  lda #$0D                ; Load CR character
  phx
  ldx PUT_CHAR
  jsr SYSCALL             ; Output newline
  plx
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
draw_world_put_cell:
  lda #'#'                ; Print live cell
  inc CELL_POPULATION_L
  bne draw_world_put_bit
  inc CELL_POPULATION_H
draw_world_put_bit:
  phx
  ldx PUT_CHAR
  jsr SYSCALL             ; Output cell
  plx
  lsr ITERATING_BIT       ; Shift iterating bit
  dex
  bne draw_world_loop_j
  iny
  cpy #WORLD_SIZE
  bne draw_world_loop_i
  ; Output population string
  lda #$0D
  phx
  ldx PUT_CHAR
  jsr SYSCALL
  lda #$D8
  sta PUT_STRING_L
  lda #$07
  sta PUT_STRING_H
  ldx PUT_STRING
  jsr SYSCALL
  plx
  lda CELL_POPULATION_H
  jsr WOZMON_PRBYTE
  lda CELL_POPULATION_L
  jsr WOZMON_PRBYTE
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
  phx
  ldx GET_RANDOM_NUMBER
  jsr SYSCALL
  plx
  cmp SPAWN_WEIGHT
  beq random_spawn_eq   ; Always spawn if equal so board can be 100% cells.  (Empty board impossible, but clear world subroutine exists)
  bcs random_spawn_next ; If random number - weight is positive, do not spawn
random_spawn_eq:
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

