	include "./sysvars.inc.asm"

; **************************************************************
; * ROM routine helper defs
; **************************************************************

ROM_LINE_NUMBER_PRINTING equ $1A1B
ROM_STACK_BC equ $2D2B
ROM_PRINT_FLOATING_POINT equ $2DE3
ROM_CLS equ $0daf
ROM_PRINT equ $203C
ROM_SET_BORDER equ $229B

; -------------------------------------------------------------

INK                     EQU 0x10
PAPER                   EQU 0x11
FLASH                   EQU 0x12
BRIGHT                  EQU 0x13
INVERSE                 EQU 0x14
OVER                    EQU 0x15
AT                      EQU 0x16
TAB                     EQU 0x17
CR                      EQU 0x0C
