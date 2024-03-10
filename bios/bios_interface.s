; System reset subroutine
.import RESET
; System halt with error subroutine
.import HALT_ERROR
; System halt with done subroutine
.import HALT_DONE
; System halt with code (register A) subroutine
.import HALT_CODE
; System routine to put char in register A
.import PUT_CHAR
; System routine to put null-terminated string starting at PUT_STRING
.import PUT_STRING
; Copy Y bytes from SYS_MEMCPY_SRC to SYS_MEMCPY_DEST.  Y==0 copies 256 bytes
.import MEMCPY
; System utility to get a random number (output in A)
.import GET_RANDOM_NUMBER
; WOZMON Functions
.import WOZMON
.import WOZMON_GETLINE
.import WOZMON_PRBYTE
.import WOZMON_PRHEX
.import WOZMON_ECHO 

; System Argument Assignments
.import SYSTEM_ARG_0
.import SYSTEM_ARG_1
.import SYSTEM_ARG_2
.import SYSTEM_ARG_3
.import SYSTEM_ARG_4
.import SYSTEM_ARG_5
.import SYSTEM_ARG_6
.import SYSTEM_ARG_7
.import PUT_STRING_L
.import PUT_STRING_H
.import DELAY_TICKS_L
.import DELAY_TICKS_H
.import SYS_MEMCPY_SRC_L
.import SYS_MEMCPY_SRC_H
.import SYS_MEMCPY_DEST_L
.import SYS_MEMCPY_DEST_H
.import SYS_MEMCPY_SIZE_L
.import SYS_MEMCPY_SIZE_H

; System Variables
.import INPUT_BUFFER
.import SYSTEM_TEMP_0
.import SYSTEM_TEMP_1
.import SYSTEM_TEMP_2
.import SYSTEM_TEMP_3
.import SYSTEM_TEMP_4
.import SYSTEM_TEMP_5
.import SYSTEM_TEMP_6
.import SYSTEM_TEMP_7
.import SYSTIME_F
.import SYSTIME_0
.import SYSTIME_1
.import SYSTIME_2
.import SYSTIME_3
.import INPUT_BUFFER_R
.import INPUT_BUFFER_W
.import LCD_STATE_SYS
.import SYS_RNG_SEED_L
.import SYS_RNG_SEED_H
.import SYS_RNG_OUTPUT_L
.import SYS_RNG_OUTPUT_H