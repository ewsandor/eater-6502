; General System Static Data

.segment "RODATA"
lcd_char_mapping:
.export LCD_CHAR_MAPPING := lcd_char_mapping
  .byte "????????????????"       ; $0X
  .byte "????????????????"       ; $1X
  .byte " !",$22,"#$%&'()*+,-./" ; $2X
  .byte "0123456789:",$3B,"<=>?" ; $3X
  .byte "@ABCDEFGHIJKLMNO"       ; $4X
  .byte "PQRSTUVWXYZ[",$A4,"]^_" ; $5X
  .byte "`abcdefghijklmno"       ; $6X
  .byte "pqrstuvwxyz{|}~?"       ; $7X
  .byte "????????????????"       ; $8X
  .byte "????????????????"       ; $9X
  .byte "????????????????"       ; $AX
  .byte "????????????????"       ; $BX
  .byte "????????????????"       ; $CX
  .byte "????????????????"       ; $DX
  .byte "????????????????"       ; $EX
  .byte "????????????????"       ; $FX