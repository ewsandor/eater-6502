  include eeprom/definitions.s

; RAM variabes
CURRENT_WORLD_L = $00
CURRENT_WORLD_H = $01
ITERATING_BIT   = $02   ; Temporary variable for iterating 
SPAWN_WEIGHT    = $0600 ; Threshold to spawn cell
WORLD_BUFFER_A  = $2000
WORLD_BUFFER_B  = $2100

; Constants
; 40x40 World
WORLD_WIDTH  = 5                            ; 1/8th world width (each bit is one entry)
WORLD_HEIGHT = 40                           ; Number of world rows
WORLD_SIZE   = (WORLD_WIDTH * WORLD_HEIGHT)

; Helper subroutines
  .org $0700
clear_world_main:
  jsr clear_world
  jmp WOZMON

  .org $0710
random_spawn_main:
  jsr clear_world
  jsr random_spawn
  jmp WOZMON

  .org $0720
draw_world_main:
  lda #00
  sta CURRENT_WORLD_L
  lda #20
  sta CURRENT_WORLD_H
  jsr draw_world
  jmp WOZMON

; Internal subroutines
  .org $0730
draw_world:
  ldy #$00                ; Reset byte iterator
draw_world_loop_i:
  lda #$80                ; Set interating bit
  sta ITERATING_BIT       ; Store in temporary variable
  ldx #$08                ; Iterate 8 bits using Y
draw_world_loop_j:
  lda ITERATING_BIT       ; Load current iterating bit
  and (CURRENT_WORLD_L),y ; Compare with world byte
  lda #'#'                ; Print live cell
  bne draw_world_put_bit
  lda #' '                ; Print dead cell 
draw_world_put_bit:
  jsr PUT_CHAR            ; Output cell
  lsr ITERATING_BIT       ; Shift iterating bit
  dex
  bne draw_world_loop_j
  tya                     ; Transfer Y to A
  and #$07                ; Mask lower 3 bits to check if multiple of 5 (ends in 0 or 5)
  cmp #$00                ; Check if ends in 0
  beq draw_world_carriage_return
  cmp #$05                ; Check if ends in 5
  bne draw_world_next_byte
draw_world_carriage_return:
  lda #$0D                ; Load CR character
  jsr PUT_CHAR            ; Output newline
draw_world_next_byte;
  iny
  cpy #WORLD_SIZE
  bne draw_world_loop_i
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
  ldx #$00                 ; Reset byte iterator
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
  ora WORLD_BUFFER_A,x  ; OR-in current mask in current world byte
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


  .org $0800
main:
  ; Init current world with 'Buffer A' address
  lda #00
  sta CURRENT_WORLD_L
  lda #20
  sta CURRENT_WORLD_H
main_loop:
  jsr draw_world ; Draw current world
  ; TODO compute next frame
  ; Set new world active (toggle address bit)
  lda CURRENT_WORLD_H
  eor #$01
  sta CURRENT_WORLD_H
  jmp main_loop