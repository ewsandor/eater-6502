BOARD_WIDTH  = 10                           ; 1/8th board width (each bit is one entry)
BOARD_HEIGHT = 24                           ; Number of board rows
BOARD_SIZE   = (BOARD_WIDTH * BOARD_HEIGHT)

BOARD_BUFFER_A = $2000
BOARD_BUFFER_B = ($2000 + BOARD_SIZE)

  .org $0800

