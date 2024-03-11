.segment "SYSCALL"
syscall:
.export SYSCALL_LBL := syscall
  pha
  txa
  clc
  rol
  bcs syscall_extended
  tax
  pla
  jmp (syscall_vector_table,x)
syscall_extended:
  tax
  pla
  jmp (syscall_vector_table_extended,x)

.import RESET_LBL
.import HALT_LBL
.import HALT_ERROR_LBL
.import HALT_CODE_LBL
.import PUT_CHAR_LBL
.import PUT_STRING_LBL
.import CHAR_AVAILABLE_LBL
.import GET_CHAR_LBL
.import MEMCPY_LBL
.import MEMCPY_LARGE_LBL
.import GET_RANDOM_NUMBER_LBL
.import DELAY_TICKS_LBL

.segment "SYSCALL_VECTOR"
syscall_vector_table:
.word RESET_LBL            ; $00
.word HALT_LBL             ; $01
.word HALT_ERROR_LBL       ; $02
.word HALT_CODE_LBL        ; $03
.word PUT_CHAR_LBL         ; $04
.word PUT_STRING_LBL       ; $05
.word CHAR_AVAILABLE_LBL   ; $06
.word GET_CHAR_LBL         ; $07
.word MEMCPY_LBL           ; $08
.word MEMCPY_LARGE_LBL     ; $09
.word GET_RANDOM_NUMBER_LBL; $0A
.word DELAY_TICKS_LBL      ; $0B
.word HALT_ERROR_LBL       ; $0C
.word HALT_ERROR_LBL       ; $0D
.word HALT_ERROR_LBL       ; $0E
.word HALT_ERROR_LBL       ; $0F
.word HALT_ERROR_LBL       ; $10
.word HALT_ERROR_LBL       ; $11
.word HALT_ERROR_LBL       ; $12
.word HALT_ERROR_LBL       ; $13
.word HALT_ERROR_LBL       ; $14
.word HALT_ERROR_LBL       ; $15
.word HALT_ERROR_LBL       ; $16
.word HALT_ERROR_LBL       ; $17
.word HALT_ERROR_LBL       ; $18
.word HALT_ERROR_LBL       ; $19
.word HALT_ERROR_LBL       ; $1A
.word HALT_ERROR_LBL       ; $1B
.word HALT_ERROR_LBL       ; $1C
.word HALT_ERROR_LBL       ; $1D
.word HALT_ERROR_LBL       ; $1E
.word HALT_ERROR_LBL       ; $1F
.word HALT_ERROR_LBL       ; $20
.word HALT_ERROR_LBL       ; $21
.word HALT_ERROR_LBL       ; $22
.word HALT_ERROR_LBL       ; $23
.word HALT_ERROR_LBL       ; $24
.word HALT_ERROR_LBL       ; $25
.word HALT_ERROR_LBL       ; $26
.word HALT_ERROR_LBL       ; $27
.word HALT_ERROR_LBL       ; $28
.word HALT_ERROR_LBL       ; $29
.word HALT_ERROR_LBL       ; $2A
.word HALT_ERROR_LBL       ; $2B
.word HALT_ERROR_LBL       ; $2C
.word HALT_ERROR_LBL       ; $2D
.word HALT_ERROR_LBL       ; $2E
.word HALT_ERROR_LBL       ; $2F
.word HALT_ERROR_LBL       ; $30
.word HALT_ERROR_LBL       ; $31
.word HALT_ERROR_LBL       ; $32
.word HALT_ERROR_LBL       ; $33
.word HALT_ERROR_LBL       ; $34
.word HALT_ERROR_LBL       ; $35
.word HALT_ERROR_LBL       ; $36
.word HALT_ERROR_LBL       ; $37
.word HALT_ERROR_LBL       ; $38
.word HALT_ERROR_LBL       ; $39
.word HALT_ERROR_LBL       ; $3A
.word HALT_ERROR_LBL       ; $3B
.word HALT_ERROR_LBL       ; $3C
.word HALT_ERROR_LBL       ; $3D
.word HALT_ERROR_LBL       ; $3E
.word HALT_ERROR_LBL       ; $3F
.word HALT_ERROR_LBL       ; $40
.word HALT_ERROR_LBL       ; $41
.word HALT_ERROR_LBL       ; $42
.word HALT_ERROR_LBL       ; $43
.word HALT_ERROR_LBL       ; $44
.word HALT_ERROR_LBL       ; $45
.word HALT_ERROR_LBL       ; $46
.word HALT_ERROR_LBL       ; $47
.word HALT_ERROR_LBL       ; $48
.word HALT_ERROR_LBL       ; $49
.word HALT_ERROR_LBL       ; $4A
.word HALT_ERROR_LBL       ; $4B
.word HALT_ERROR_LBL       ; $4C
.word HALT_ERROR_LBL       ; $4D
.word HALT_ERROR_LBL       ; $4E
.word HALT_ERROR_LBL       ; $4F
.word HALT_ERROR_LBL       ; $50
.word HALT_ERROR_LBL       ; $51
.word HALT_ERROR_LBL       ; $52
.word HALT_ERROR_LBL       ; $53
.word HALT_ERROR_LBL       ; $54
.word HALT_ERROR_LBL       ; $55
.word HALT_ERROR_LBL       ; $56
.word HALT_ERROR_LBL       ; $57
.word HALT_ERROR_LBL       ; $58
.word HALT_ERROR_LBL       ; $59
.word HALT_ERROR_LBL       ; $5A
.word HALT_ERROR_LBL       ; $5B
.word HALT_ERROR_LBL       ; $5C
.word HALT_ERROR_LBL       ; $5D
.word HALT_ERROR_LBL       ; $5E
.word HALT_ERROR_LBL       ; $5F
.word HALT_ERROR_LBL       ; $60
.word HALT_ERROR_LBL       ; $61
.word HALT_ERROR_LBL       ; $62
.word HALT_ERROR_LBL       ; $63
.word HALT_ERROR_LBL       ; $64
.word HALT_ERROR_LBL       ; $65
.word HALT_ERROR_LBL       ; $66
.word HALT_ERROR_LBL       ; $67
.word HALT_ERROR_LBL       ; $68
.word HALT_ERROR_LBL       ; $69
.word HALT_ERROR_LBL       ; $6A
.word HALT_ERROR_LBL       ; $6B
.word HALT_ERROR_LBL       ; $6C
.word HALT_ERROR_LBL       ; $6D
.word HALT_ERROR_LBL       ; $6E
.word HALT_ERROR_LBL       ; $6F
.word HALT_ERROR_LBL       ; $70
.word HALT_ERROR_LBL       ; $71
.word HALT_ERROR_LBL       ; $72
.word HALT_ERROR_LBL       ; $73
.word HALT_ERROR_LBL       ; $74
.word HALT_ERROR_LBL       ; $75
.word HALT_ERROR_LBL       ; $76
.word HALT_ERROR_LBL       ; $77
.word HALT_ERROR_LBL       ; $78
.word HALT_ERROR_LBL       ; $79
.word HALT_ERROR_LBL       ; $7A
.word HALT_ERROR_LBL       ; $7B
.word HALT_ERROR_LBL       ; $7C
.word HALT_ERROR_LBL       ; $7D
.word HALT_ERROR_LBL       ; $7E
.word HALT_ERROR_LBL       ; $7F
syscall_vector_table_extended:
.word HALT_ERROR_LBL       ; $80
.word HALT_ERROR_LBL       ; $81
.word HALT_ERROR_LBL       ; $82
.word HALT_ERROR_LBL       ; $83
.word HALT_ERROR_LBL       ; $84
.word HALT_ERROR_LBL       ; $85
.word HALT_ERROR_LBL       ; $86
.word HALT_ERROR_LBL       ; $87
.word HALT_ERROR_LBL       ; $88
.word HALT_ERROR_LBL       ; $89
.word HALT_ERROR_LBL       ; $8A
.word HALT_ERROR_LBL       ; $8B
.word HALT_ERROR_LBL       ; $8C
.word HALT_ERROR_LBL       ; $8D
.word HALT_ERROR_LBL       ; $8E
.word HALT_ERROR_LBL       ; $8F
.word HALT_ERROR_LBL       ; $90
.word HALT_ERROR_LBL       ; $91
.word HALT_ERROR_LBL       ; $92
.word HALT_ERROR_LBL       ; $93
.word HALT_ERROR_LBL       ; $94
.word HALT_ERROR_LBL       ; $95
.word HALT_ERROR_LBL       ; $96
.word HALT_ERROR_LBL       ; $97
.word HALT_ERROR_LBL       ; $98
.word HALT_ERROR_LBL       ; $99
.word HALT_ERROR_LBL       ; $9A
.word HALT_ERROR_LBL       ; $9B
.word HALT_ERROR_LBL       ; $9C
.word HALT_ERROR_LBL       ; $9D
.word HALT_ERROR_LBL       ; $9E
.word HALT_ERROR_LBL       ; $9F
.word HALT_ERROR_LBL       ; $A0
.word HALT_ERROR_LBL       ; $A1
.word HALT_ERROR_LBL       ; $A2
.word HALT_ERROR_LBL       ; $A3
.word HALT_ERROR_LBL       ; $A4
.word HALT_ERROR_LBL       ; $A5
.word HALT_ERROR_LBL       ; $A6
.word HALT_ERROR_LBL       ; $A7
.word HALT_ERROR_LBL       ; $A8
.word HALT_ERROR_LBL       ; $A9
.word HALT_ERROR_LBL       ; $AA
.word HALT_ERROR_LBL       ; $AB
.word HALT_ERROR_LBL       ; $AC
.word HALT_ERROR_LBL       ; $AD
.word HALT_ERROR_LBL       ; $AE
.word HALT_ERROR_LBL       ; $AF
.word HALT_ERROR_LBL       ; $B0
.word HALT_ERROR_LBL       ; $B1
.word HALT_ERROR_LBL       ; $B2
.word HALT_ERROR_LBL       ; $B3
.word HALT_ERROR_LBL       ; $B4
.word HALT_ERROR_LBL       ; $B5
.word HALT_ERROR_LBL       ; $B6
.word HALT_ERROR_LBL       ; $B7
.word HALT_ERROR_LBL       ; $B8
.word HALT_ERROR_LBL       ; $B9
.word HALT_ERROR_LBL       ; $BA
.word HALT_ERROR_LBL       ; $BB
.word HALT_ERROR_LBL       ; $BC
.word HALT_ERROR_LBL       ; $BD
.word HALT_ERROR_LBL       ; $BE
.word HALT_ERROR_LBL       ; $BF
.word HALT_ERROR_LBL       ; $C0
.word HALT_ERROR_LBL       ; $C1
.word HALT_ERROR_LBL       ; $C2
.word HALT_ERROR_LBL       ; $C3
.word HALT_ERROR_LBL       ; $C4
.word HALT_ERROR_LBL       ; $C5
.word HALT_ERROR_LBL       ; $C6
.word HALT_ERROR_LBL       ; $C7
.word HALT_ERROR_LBL       ; $C8
.word HALT_ERROR_LBL       ; $C9
.word HALT_ERROR_LBL       ; $CA
.word HALT_ERROR_LBL       ; $CB
.word HALT_ERROR_LBL       ; $CC
.word HALT_ERROR_LBL       ; $CD
.word HALT_ERROR_LBL       ; $CE
.word HALT_ERROR_LBL       ; $CF
.word HALT_ERROR_LBL       ; $D0
.word HALT_ERROR_LBL       ; $D1
.word HALT_ERROR_LBL       ; $D2
.word HALT_ERROR_LBL       ; $D3
.word HALT_ERROR_LBL       ; $D4
.word HALT_ERROR_LBL       ; $D5
.word HALT_ERROR_LBL       ; $D6
.word HALT_ERROR_LBL       ; $D7
.word HALT_ERROR_LBL       ; $D8
.word HALT_ERROR_LBL       ; $D9
.word HALT_ERROR_LBL       ; $DA
.word HALT_ERROR_LBL       ; $DB
.word HALT_ERROR_LBL       ; $DC
.word HALT_ERROR_LBL       ; $DD
.word HALT_ERROR_LBL       ; $DE
.word HALT_ERROR_LBL       ; $DF
.word HALT_ERROR_LBL       ; $E0
.word HALT_ERROR_LBL       ; $E1
.word HALT_ERROR_LBL       ; $E2
.word HALT_ERROR_LBL       ; $E3
.word HALT_ERROR_LBL       ; $E4
.word HALT_ERROR_LBL       ; $E5
.word HALT_ERROR_LBL       ; $E6
.word HALT_ERROR_LBL       ; $E7
.word HALT_ERROR_LBL       ; $E8
.word HALT_ERROR_LBL       ; $E9
.word HALT_ERROR_LBL       ; $EA
.word HALT_ERROR_LBL       ; $EB
.word HALT_ERROR_LBL       ; $EC
.word HALT_ERROR_LBL       ; $ED
.word HALT_ERROR_LBL       ; $EE
.word HALT_ERROR_LBL       ; $EF
.word HALT_ERROR_LBL       ; $F0
.word HALT_ERROR_LBL       ; $F1
.word HALT_ERROR_LBL       ; $F2
.word HALT_ERROR_LBL       ; $F3
.word HALT_ERROR_LBL       ; $F4
.word HALT_ERROR_LBL       ; $F5
.word HALT_ERROR_LBL       ; $F6
.word HALT_ERROR_LBL       ; $F7
.word HALT_ERROR_LBL       ; $F8
.word HALT_ERROR_LBL       ; $F9
.word HALT_ERROR_LBL       ; $FA
.word HALT_ERROR_LBL       ; $FB
.word HALT_ERROR_LBL       ; $FC
.word HALT_ERROR_LBL       ; $FD
.word HALT_ERROR_LBL       ; $FE
.word HALT_ERROR_LBL       ; $FF