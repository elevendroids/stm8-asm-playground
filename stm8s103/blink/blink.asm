.stm8
;
; STM8 assembler LED blink demo
;

; CPU clock frequency, required by delay routines
F_CPU equ 16000000
; LED pin index on Port B
LED equ 5
; Blink interval in ms
DELAY equ 250

; CLK_CKDIVR flags
HSIDIV_00 equ 0x00  ; HSI prescaler: fHSI / 1
CPUDIV_000 equ 0x00 ; CPU prescaler: fMASTER / 1

; code start
.org 0x8080

.include "chips/stm8s103.inc"
.include "functions/delay_ms.inc"

start:
    mov     CLK_CKDIVR, #(HSIDIV_00 | CPUDIV_000)   ; clock setup
    bset    PB_DDR, #LED        ; set the LED pin as output
    bset    PB_CR1, #LED        ; set the LED pin as push-pull
    bset    PB_CR2, #LED        ; set the output speed to high (<= 10MHz)

loop:
    ldw     X, #DELAY           ; load the blink interval
    call delay_ms               ; wait for the DELAY ms
    bcpl    PB_ODR, #LED        ; toggle the LED pin
    jp loop                     ; loop forever

; interrupt vectors
.org 0x8000
    int start       ; RESET handler, jump to the main program body

