; Useful WOZMON Routines
WOZMON            = $FF00
WOZMON_GETLINE    = $FF1F
WOZMON_PRBYTE     = $FFDC
WOZMON_PRHEX      = $FFE5
WOZMON_ECHO       = $FFEF

; System Calls
SYSCALL           = $8000
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

; System Variables
INPUT_BUFFER = $0300 ; Base address of input buffer ($0300-$03FF)
SYSTEM_TEMP_0      = $E8
SYSTEM_TEMP_1      = $E9
SYSTEM_TEMP_2      = $EA
SYSTEM_TEMP_3      = $EB
SYSTEM_TEMP_4      = $EC
SYSTEM_TEMP_5      = $ED
SYSTEM_TEMP_6      = $EE
SYSTEM_TEMP_7      = $EF
SYSTIME_F          = $F0 ; Frantional-seconds (1/256) portion of SYSTIME
SYSTIME_0          = $F1 ; First (lowest) byte of SYSTIME in seconds
SYSTIME_1          = $F2 ; Second byte of SYSTIME in seconds
SYSTIME_2          = $F3 ; Third byte of SYSTIME in seconds
SYSTIME_3          = $F4 ; Fourth (highest) byte of SYSTIME in seconds
INPUT_BUFFER_R     = $F5 ; Next input buffer read index
INPUT_BUFFER_W     = $F6 ; Next input buffer write index
LCD_STATE_SYS      = $FA ; LCD system state register 
SYS_RNG_SEED_L     = $0280 ; Low-byte of RNG seed
SYS_RNG_SEED_H     = $0281 ; High-byte of RNG seed
SYS_RNG_OUTPUT_L   = $0282 ; Low-byte of RNG output
SYS_RNG_OUTPUT_H   = $0283 ; High-byte of RNG input
; System Argument Assignments
SYSTEM_ARG_0       = $FC
SYSTEM_ARG_1       = $FD
SYSTEM_ARG_2       = $FE
SYSTEM_ARG_3       = $FF
SYSTEM_ARG_4       = $02FC
SYSTEM_ARG_5       = $02FD
SYSTEM_ARG_6       = $02FE
SYSTEM_ARG_7       = $02FF
PUT_STRING_L       = SYSTEM_ARG_0 ; Put string Low-Byte
PUT_STRING_H       = SYSTEM_ARG_1 ; Put string High-Byte
DELAY_TICKS_L      = SYSTEM_ARG_0 ; Delay Counter Low-Byte
DELAY_TICKS_H      = SYSTEM_ARG_1 ; Delay Counter High-Byte
SYS_MEMCPY_SRC_L   = SYSTEM_ARG_0
SYS_MEMCPY_SRC_H   = SYSTEM_ARG_1
SYS_MEMCPY_DEST_L  = SYSTEM_ARG_2
SYS_MEMCPY_DEST_H  = SYSTEM_ARG_3
SYS_MEMCPY_SIZE_L  = SYSTEM_ARG_4
SYS_MEMCPY_SIZE_H  = SYSTEM_ARG_5