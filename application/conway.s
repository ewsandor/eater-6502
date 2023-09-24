
  .org $0800

; Psuedo-random number generator from "Super Mario World" 
;    Thanks to 'Retro Game Mechanics Explained' (https://www.youtube.com/watch?v=q15yNrJHOak&t=1s)
RANDOM_NUMBER_SEED_L   = $148B
RANDOM_NUMBER_SEED_H   = $148C
RANDOM_NUMBER_OUTPUT_L = $148D
RANDOM_NUMBER_OUTPUT_H = $148E
get_random_number:
  phy
  ldy #$01
  jsr get_random_number_tick
  dey
  jsr get_random_number_tick
  ply
  rts
get_random_number_tick:
  lda RANDOM_NUMBER_SEED_L
  asl
  asl
  sec
  adc RANDOM_NUMBER_SEED_L
  sta RANDOM_NUMBER_SEED_L
  asl RANDOM_NUMBER_SEED_H
  lda #$20
  bit RANDOM_NUMBER_SEED_H
  bcc get_random_number_tick_label1
  beq get_random_number_tick_label3
  bne get_random_number_tick_label2
get_random_number_tick_label1:
  bne get_random_number_tick_label3
get_random_number_tick_label2:
  inc RANDOM_NUMBER_SEED_H
get_random_number_tick_label3:
  lda RANDOM_NUMBER_SEED_H
  eor RANDOM_NUMBER_SEED_L
  sta RANDOM_NUMBER_OUTPUT_L,y
  rts