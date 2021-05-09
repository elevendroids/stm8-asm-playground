.stm8
;
; STM8 assembler Hello World demo
;

.include "chips/stm8s103.inc"

; code start
.org 0x8080

; our string
hello: .asciiz "Hello World!"

start:
    mov     CLK_CKDIVR, #0x00               ; clock setup (16MHz from HSI)
                                            ; UART setup (note that UART is by default in 8n1 mode)
    mov     UART1_BRR2, #0x0b               ; Set the baud rate to 115200 bps, BRR2 needs to be set first
    mov     UART1_BRR1, #0x08               ;
    bset    UART1_CR2, #3                   ; Enable UART transmitter

    ldw     X, #hello                       ; load the start address of the string
get_next_char:
    ld      A, (X)                          ; read the character at X
    jreq    end                             ; check for null terminator, end when we're done
wait_tx_buf:
    btjf    UART1_SR, #7, wait_tx_buf       ; wait until the TX buffer is empty (TXE bit is set)
    ld      UART1_DR, A                     ; copy the character to UART's data register
    incw    X                               ; increment the character address
    jp      get_next_char                   ; send next character

end:
    jp end                                  ; loop forever

; interrupt vectors
.org 0x8000
    int start                               ; RESET handler, jump to the main program body
