.stm8
;
; STM8 assembler demo:
; LED blinking on a timer interrupt
;

; LED pin index on Port B
LED equ 5

; Code start
.org 0x8080

.include "chips/stm8s103.inc"

;
; Main program body
;
start:
    sim                         ; Disable interrupts
    bset    PB_DDR, #LED        ; Set the LED pin as output
    bset    PB_CR1, #LED        ; Set the LED pin as push-pull

    mov     TIM2_ARRH, #0x7A    ; Set the auto-reload value to 31250
    mov     TIM2_ARRL, #0x12    ; which should give us the interrupt interval of:
                                ; 1 / (2000000 / 32 / 31250) = 0.5 s
    mov     TIM2_PSCR, #5       ; Set the prescaler to divide the clock by 32
    bset    TIM2_IER, #0        ; Enable update interrupt
    rim                         ; Enable interrupts

    bset    TIM2_CR1, #0        ; Enable the timer
loop:
    wfi                         ; wait for an interrupt
    jp      loop                ; loop forever

;
; TIM2 update/overflow handler
;
.func tim2_overflow
    bcpl    PB_ODR, #LED        ; Toggle the LED pin
    bres    TIM2_SR1, #0        ; Reset timer's update interrupt flag
    iret
.endf

; Interrupt vectors
.org 0x8000
    int start                   ; RESET handler, jump to the main program body

.org 0x803c
    int tim2_overflow           ; IRQ13: TIM2 update/overflow interrupt
