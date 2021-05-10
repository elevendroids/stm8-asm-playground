.stm8
;
; STM8 assembler UART echo demo
; Echoes (transmits) back every character received on the UART
;

.include "chips/stm8s103.inc"

; code start
.org 0x8080

start:
    mov     CLK_CKDIVR, #0x00               ; clock setup (16MHz from HSI)
                                            ; UART setup (note that UART is by default in 8n1 mode)
    mov     UART1_BRR2, #0x0b               ; Set the baud rate to 115200 bps, BRR2 needs to be set first
    mov     UART1_BRR1, #0x08               ;
    mov     UART1_CR2, #(1<<3|1<<2)         ; Enable UART transmitter and receiver

loop:
wait_rx:
    btjf    UART1_SR, #5, wait_rx           ; wait for a received character
    ld      A, UART1_DR                     ; read it
wait_tx:
    btjf    UART1_SR, #7, wait_tx           ; wait for the transmit register to be empty
    ld      UART1_DR, A                     ; transmit the received character
    jp loop                                 ; loop forever

; interrupt vectors
.org 0x8000
    int start                               ; RESET handler, jump to the main program body
