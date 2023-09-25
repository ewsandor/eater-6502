; Common system definitions to be referenced by applications

; Fixed Addresses
; Starting address of EEPROM
EEPROM_START_ADDRESS=$8000
; Starting address of static data block
STATIC_DATA_ADDRESS =$E000
; Non-Maskable Interrupt Vector Address
NMIB_VECTOR         =$FFFA
; Reset Vector Address
RESB_VECTOR         =$FFFC
; Interrupt Vector Address
IRQB_VECTOR         =$FFFE


; System Subroutines
; System reset subroutine
RESET       = $8100
; System reset subroutine
HALT_ERROR  = $8200
; System reset subroutine
HALT_DONE   = $8208
; System reset subroutine
HALT_CODE   = $8210
; Miscellaneous system subroutines
SYSTEM_MISC = $D000
; Starting address of WOZMON
WOZMON      = $FF00

; 6522 VIA Registers
VIA_PORTB    = $6000 ; Output/Input Register B (PORTB)
VIA_PORTA    = $6001 ; Output/Input Register A (PORTA)
VIA_DDRB     = $6002 ; Data Direction Register B
VIA_DDRA     = $6003 ; Data Direction Register A
VIA_T1CL     = $6004 ; Timer 1 Low-Order Latches/Counter
VIA_T1CH     = $6005 ; Timer 1 High-Order Counter
VIA_T1LL     = $6006 ; Timer 1 Low-Order Latches
VIA_T1LH     = $6007 ; Timer 1 High-Order Latches
VIA_T2CL     = $6008 ; Timer 2 Low-Order Latches/Counter
VIA_T2CH     = $6009 ; Timer 2 High-Order Counter
VIA_SR       = $600A ; Shift Register
VIA_ACR      = $600B ; Auxillary Control Register
VIA_PCR      = $600C ; Peripheral Control Register
VIA_IFR      = $600D ; Interrupt Flag Register
VIA_IER      = $600E ; Interrupt Enable Registser
VIA_PORT_NHS = $600F ; Output/Input Register A except no "Handshake"
; 6522 VIA Constants
VIA_IFR_CA2  = $01
VIA_IFR_CA1  = $02
VIA_IFR_SR   = $04
VIA_IFR_CB2  = $08
VIA_IFR_CB1  = $10
VIA_IFR_T2   = $20
VIA_IFR_T1   = $40
VIA_IFR_ANY  = $80
VIA_IER_SET  = $80 ; IER set mode

; LCD Constants
LCD_RS        = $10 ; LCD Register Select on PORT B bit 4
LCD_RW        = $20 ; LCD Read/Write on PORT B bit 5
LCD_EN        = $40 ; LCD Enable on PORT B bit 6
LCD_BUSY      = $08 ; LCD Busy flag on PORT B bit 3
LCD_WRITE_DDR = $7F ; PORTB DDR mask when writing
LCD_READ_DDR  = $70 ; PORTB DDR mask when writing



; 6551 ACIA Register
ACIA_DATA        = $5000 ; Write transmit data/Read receiver data
ACIA_STATUS      = $5001 ; Status register
ACIA_COMMAND     = $5002 ; Command register
ACIA_CONTROL     = $5003 ; Control register
; 6551 ACIA Constants
ACIA_BAUD_115200 = $00
ACIA_BAUD_9600   = $0E
ACIA_BAUD_19200  = $0F
ACIA_WL_8_BITS   = $00 ; Word length
ACIA_WL_7_BITS   = $20
ACIA_WL_6_BITS   = $40
ACIA_WL_5_BITS   = $60
ACIA_CLOCK_EXT   = $00 ; Use external baud clock
ACIA_CLOCK_BAUD  = $10 ; Use baud clock generator
ACIA_STOP_BITS_1 = $00
ACIA_STOP_BITS_2 = $80
ACIA_DTR_ENABLE  = $01
ACIA_RTSB_HIGH   = $00
ACIA_RTSB_LOW    = $08
ACIA_ECHO        = $10
ACIA_STATUS_PE   = $01 ; Parity Error
ACIA_STATUS_FE   = $02 ; Framing Error
ACIA_STATUS_OVRN = $04 ; Overrun Error
ACIA_STATUS_RDRF = $08 ; Receiver Data Register Full
ACIA_STATUS_TDRE = $10 ; Transmit Data Register Empty
ACIA_STATUS_DCDB = $20 ; Data Carrier Detect
ACIA_STATUS_DSRB = $40 ; Data Set Ready
ACIA_STATUS_IRQ  = $80 ; Interrupt


; System Variables
INPUT_BUFFER       = $0300 ; Base address of input buffer ($0300-$03FF)
SYSTIME_F          = $F0 ; Frantional-seconds (1/256) portion of SYSTIME
SYSTIME_0          = $F1 ; First (lowest) byte of SYSTIME in seconds
SYSTIME_1          = $F2 ; Second byte of SYSTIME in seconds
SYSTIME_2          = $F3 ; Third byte of SYSTIME in seconds
SYSTIME_3          = $F4 ; Fourth (highest) byte of SYSTIME in seconds
INPUT_BUFFER_R     = $F5 ; Next input buffer read index
INPUT_BUFFER_W     = $F6 ; Next input buffer write index
LCD_STATE_SYS      = $FB ; LCD system state register 
PUT_STRING_L       = $FC ; Put string Low-Byte
PUT_STRING_H       = $FD ; Put string High-Byte
DELAY_TICKS_L      = $FE ; Delay Counter Low-Byte
DELAY_TICKS_H      = $FF ; Delay Counter High-Byte
; System Flags
LCD_STATE_SYS_LINE = $01


; WOZMON Variables
WOZMON_XAML = $24
WOZMON_XAMH = $25
WOZMON_STL  = $26
WOZMON_STH  = $27
WOZMON_L    = $28
WOZMON_H    = $29
WOZMON_YSAV = $2A
WOZMON_MODE = $2B
WOZMON_IN   = $0200