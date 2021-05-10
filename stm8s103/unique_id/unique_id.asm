.stm8
;
; STM8 assembler unique ID demo
;
; This program prints out the built-in, 96-bit unique device identifier as a hex string.
;
; Note that the Value Line devices (STM8S00x) are not supposed to have the IDs but they
; do seem to have them in practice:
; https://hackaday.io/project/16097-eforth-for-cheap-stm8s-gadgets/log/51498-whats-the-difference-between-stm8s003f3p-and-stm8s103f3p6
;
; Expected output:
; Unique ID: 00000000000000000000000000
;

.include "chips/stm8s103.inc"

; Code/data section
.org CODE_START

;
; String constants
;
title:  .asciiz "Unique ID: "
crlf:   .asciiz "\r\n"

;
; Main code
;
start:
    mov     CLK_CKDIVR, #0x00               ; clock setup (16MHz from HSI)
                                            ; UART setup (note that UART is by default in 8n1 mode)
    mov     UART1_BRR2, #0x0b               ; Set the baud rate to 115200 bps, BRR2 needs to be set first
    mov     UART1_BRR1, #0x08               ;
    bset    UART1_CR2, #3                   ; Enable UART transmitter

    ldw     X, #title                       ; load the start address of the string
    pushw   X                               ; store it on the stack (as a function param)
    call    uart1_write_str                 ; print it out
    popw    X                               ; clean the stack

    ldw     X, #U_ID                        ; load the start address of the UID
next_byte:
    ld      A, (X)                          ; load the byte
; print the high nibble
    swap    A                               ; swap the high and low nibbles
    and     A, #0x0F                        ; mask-out the high nibble
    push    A                               ; store the nibble as a function param
    call    print_hex_digit                 ; print it out
    pop     A                               ; clean the stack
; print the low nibble
    ld      A, (X)                          ; re-load the byte
    and     A, #0x0F                        ; mask-out the high nibble
    push    A                               ; store the nibble as a function param
    call    print_hex_digit                 ; print it out
    pop     A                               ; clean the stack

    cpw     X, #(U_ID + U_ID_SIZE)          ; check if this was the last UID byte
    jreq    end                             ; jump out to the end if so
    incw    X                               ; increment the byte address
    jp      next_byte                       ; process the next one

end:
; print a newline sequence at the end
    ldw     X, #crlf                        ; load the start address of the CRLF string
    pushw   X                               ; store it on the stack (as a function param)
    call    uart1_write_str                 ; print the string
loop:
    jp loop                                 ; loop forever

;
; Helper functions
;

;
; Prints out a single hexadecimal digit
; Params on stack:
; - single 4-bit (0-15) value to print out
;
.func print_hex_digit
    ld      A, (0x03, SP)                   ; load the nibble value
    cp      A, #10                          ; digit (0-9) or letter (A-F) ?
    jruge   hex_letter                      ; jump forward if we need a letter (val >= 10)
    add     A, #'0'                         ; compute the digit character (0-9)
    jp      print                           ; jump to the print routine
hex_letter:
    add     A, #('A' - 10)                  ; compute the letter character (A-F)
print:
    push    A                               ; store the character for the uart1_write function
    call    uart1_write                     ; print it out
    pop     A                               ; clean the stack
    ret
.endf

;
; Writes a single byte on UART1
; Params on stack:
; - a byte to transmit
;
.func uart1_write
    ld      A, (0x03, SP)
wait_tx_buf:
    btjf    UART1_SR, #7, wait_tx_buf
    ld      UART1_DR, A
    ret
.endf

;
; Writes a null-terminated string on UART1
; Params on stack:
; - a 16-bit address of the string
;
.func uart1_write_str
    ldw     X, (0x03, SP)
next_char:
    ld      A, (X)                          ; read the character at X
    jreq    exit                            ; check for null terminator, end when we're done
wait_tx_buf:
    btjf    UART1_SR, #7, wait_tx_buf
    ld      UART1_DR, A
    incw    X                               ; increment the character address
    jp      next_char                       ; process next character
exit:
    ret
.endf

;
; Interrupt vectors
;
.org VECTORS_START
    int start                               ; RESET handler, jump to the main program body
