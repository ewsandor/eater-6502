  .include "definitions.s"
; Adapted version of Steve Wozniak's Apple-I system monitor "WOZMON"

.import PUT_CHAR_LBL
.import GET_CHAR_LBL

.segment "WOZMON"
wozmon:
.export WOZMON_LBL := wozmon
  cld               ; Cleardecimal arithmetic mode
  cli               ; Enable interrupts
  ldy #$7F          ; Mask for DSP data direction register.
  nop               ; STY DSP
  nop
  nop
  lda #$A7          ; KBD and DSP control register mask.
  nop               ; STA KBD_CR
  nop
  nop
  nop               ; STA DSP_CR
  nop
  nop
wozmon_notcr:       ; Originally $FF0F
  cmp #$08          ; Backspace?
  beq wozmon_backspace
  cmp #$1B          ; Escape?
  beq wozmon_escape
  iny
  bpl wozmon_nextchar
wozmon_escape:
  lda #'\'
  jsr wozmon_echo
wozmon_getline:
.export WOZMON_GETLINE_LBL := wozmon_getline
  lda #$0D          ; CR
  jsr wozmon_echo
  ldy #$01          ; Initialize text index
wozmon_backspace:
  dey
  bmi wozmon_getline
wozmon_nextchar:
  jsr GET_CHAR_LBL  ; LDA KBD CR
  nop               ; BPL NEXTCHAR
  nop
  nop               ; LDA KB
  nop               ; Single 'nop' removed to keep this implementation closely byte alligned with original (wozmon_setblock 'asl')
  sta WOZMON_IN, y
  jsr wozmon_echo  
  cmp #$0D          ; CR?
  bne wozmon_notcr
  ldy #$FF          ; Reset text index.
  lda #$00          ; For XAM mode.
  tax
wozmon_setblock:
  asl               ; From Ben Eater's implementation since Apple I historically set bit-7 for chars unlike ASCII...
wozmon_setstor:     ; Originally $FF40
  asl               ; Leaves $7B if setting STOR mode.
wozmon_setmode:
  sta WOZMON_MODE   ; $00 = XAM, $7B = STOR, $AE = BLOK XAM.
wozmon_blskip:
  iny
wozmon_nextitem:
  lda WOZMON_IN, y  ; Get character.
  cmp #$0D          ; CR?
  beq wozmon_getline
  cmp #'.'           ; "."?
  bcc wozmon_blskip  ; Skip delimiter.
  beq wozmon_setblock ; Set BLOCK XAM mode. ; Modified from Ben Eater's implementation
  cmp #':'           ; ":"?
  beq wozmon_setstor ; Yes, set STORE mode.
  cmp #'R'           ; "R"?
  beq wozmon_run     ; Yes, run user program.
  stx WOZMON_L       ; $00->L.
  stx WOZMON_H       ; and H.
  sty WOZMON_YSAV    ; Save Y for comparison.
wozmon_nexthex:
  lda WOZMON_IN, y   ; Get character for hex test.
  eor #$30           ; Map digits to $0-9
  cmp #$0A           ; Digit?
  bcc wozmon_dig     ; Yes.
  adc #$88           ; Map letter "A"-"F" to FA-FF
  cmp #$FA           ; Hex letter?
  bcc wozmon_nothex  ; No, character not hex.
wozmon_dig:
  asl                ; Hex digit to MSD of A
  asl
  asl
  asl
  ldx #$04           ; Shift count
wozmon_hexshift:
  asl                ; Hex digit left, MSB to carry
  rol WOZMON_L       ; Rotate into LSD.
  rol WOZMON_H       ; Rotate into MSD's.
  dex                ; Done 4 shifts?
  bne wozmon_hexshift ; No, loop
  iny                 ; Advance text index.
  bne wozmon_nexthex  ; Always taken.  Check next character for hex.
wozmon_nothex:
  cpy WOZMON_YSAV     ; Check if L, H empty (no hex digits).
  beq wozmon_escape   ; Yes, generate ESC sequence.
  bit WOZMON_MODE     ; Test MODE byte.
  bvc wozmon_notstor  ; B6 = 0 for STOR, 1 for XAM and BLOCK XAM
  lda WOZMON_L        ; LSD's of hex data.
  sta (WOZMON_STL, x) ; Store at current 'store index'.
  inc WOZMON_STL      ; Increment store index.
  bne wozmon_nextitem ; Get next item. (no carry).
  inc WOZMON_STH      ; Add carry 'store index' to high order .
wozmon_tonextitem:
  jmp wozmon_nextitem  ; Get next command item.
wozmon_run:
  jmp (WOZMON_XAML)    ; Run at current XAM index.
wozmon_notstor:
  bmi wozmon_xamnext   ; B7 = 0 for XAM, 1 for BLOCK XAM.
  ldx #$02             ; Byte count.
wozmon_setadr:
  lda WOZMON_L   -1, x ; Copy hex data to
  sta WOZMON_STL -1, x ;   'store index'.
  sta WOZMON_XAML-1, x ; And to 'XAM index'.
  dex
  bne wozmon_setadr    ; Loop unless X = 0
wozmon_nxtprnt:
  bne wozmon_prdata     ; NE means no address to print.
  lda #$0D              ; CR.
  jsr wozmon_echo       ; Output it.
  lda WOZMON_XAMH       ; 'Examine index' high-order byte.
  jsr wozmon_prbyte     ; Output it in hex format.
  lda WOZMON_XAML       ; Low-order 'examine index' byte.
  jsr wozmon_prbyte     ; Output it in hex format.
  lda #':'              ; ":"
  jsr wozmon_echo       ; Output it.
wozmon_prdata:
  lda #' '              ; Blank.
  jsr wozmon_echo       ; Output it.
  lda (WOZMON_XAML, x)  ; Get data byte at 'examine index'.
  jsr wozmon_prbyte     ; Output it in hex format.
wozmon_xamnext:
  stx WOZMON_MODE       ; 0->MODE (XAM mode).
  lda WOZMON_XAML
  cmp WOZMON_L          ; Compare 'examine index' to hex data.
  lda WOZMON_XAMH
  sbc WOZMON_H
  bcs wozmon_tonextitem ; Not less, so no more data to output.
  inc WOZMON_XAML
  bne wozmon_mod8chk    ; Incrment 'examine index'.
  inc WOZMON_XAMH
wozmon_mod8chk:
  lda WOZMON_XAML       ; Check low-order 'examine index' byte
  and #$07              ;   For MOD 8 = 0
  bpl wozmon_nxtprnt    ; Always taken
wozmon_prbyte:
.export WOZMON_PRBYTE_LBL := wozmon_prbyte
  pha                   ; Save A for LSD
  lsr                   ; MSD to LSD position
  lsr
  lsr
  lsr
  jsr wozmon_prhex      ; Output hex digit.
  pla
wozmon_prhex:
.export WOZMON_PRHEX_LBL := wozmon_prhex
  and #$0F              ; Mask LSD for hex print.
  ora #$30              ; "0".
  cmp #$3A              ; Digit?
  bcc wozmon_echo       ; Yes, output it.
  adc #$06              ; Add offset for letter.
wozmon_echo:
.export WOZMON_ECHO_LBL := wozmon_echo
  jsr PUT_CHAR_LBL      ; BIT DSP 
  rts                   ; Reorder to avoid unnessesary 'nops'
  nop                   ; BMI ECHO
  nop
  nop                   ; STA DSP
  nop
  nop