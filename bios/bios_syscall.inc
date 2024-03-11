; Useful WOZMON Routines
WOZMON            = $FF00
WOZMON_GETLINE    = $FF1F
WOZMON_PRBYTE     = $FFDC
WOZMON_PRHEX      = $FFE5
WOZMON_ECHO       = $FFEF

; System Calls
; Software system reset
RESET             = $00
; System halt with 'done' code
HALT              = $01
; System halt with 'error' code
HALT_ERROR        = $02
; System halt with user's code (register A)
HALT_CODE         = $03
; System routine to put char in register A
PUT_CHAR          = $04
; System routine to put null-terminated string starting at PUT_STRING
PUT_STRING        = $05
; System routine get number of characters available from the input buffer (output in A)
CHAR_AVAILABLE    = $06
; System routine to get next character from tne input buffer (output in A)
GET_CHAR          = $07
; Copy Y bytes from SYS_MEMCPY_SRC to SYS_MEMCPY_DEST.  Y==0 copies 256 bytes
MEMCPY            = $08
; Copy SYS_MEMCPY_SIZE bytes from SYS_MEMCPY_SRC to SYS_MEMCPY_DEST
MEMCPY_LARGE      = $09
; System utility to get a random number (output in A)
GET_RANDOM_NUMBER = $0A
; System utility to delay the system for DELAY_TICKS using 'Timer 2'
DELAY_TICKS       = $0B