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
    call    uart1_write_str                 ; print it out

    ldw     Y, #U_ID                        ; load the start address of the UID
                                            ; note that we use Y here as X is clobbered by print_hex_digit
next_byte:
    ld      A, (Y)                          ; load the byte
; print the high nibble
    swap    A                               ; swap the high and low nibbles
    call    print_hex_digit                 ; print it out
; print the low nibble
    ld      A, (Y)                          ; re-load the byte (print_hex_digit modifies the accumulator)
    call    print_hex_digit                 ; print it out

    incw    Y                               ; increment the byte address
    cpw     Y, #(U_ID + U_ID_SIZE)          ; check if we're not past the last UID byte
    jrule   next_byte                       ; process the next one if so

; print a newline sequence at the end
    ldw     X, #crlf                        ; load the start address of the CRLF string
    call    uart1_write_str                 ; print the string
exit:
    jp      exit                             ; loop forever

;
; Helper functions
;

;
; Prints out a single hexadecimal digit (low byte nibble)
;
; Params:
; A - byte value to print out
;
; Clobbers:
; A, X
;
.func print_hex_digit
    and     A, #0x0F                        ; mask-out the high nibble
    clrw    X                               ; clear the index register
    ld      XL, A                           ; load the nibble into lower X
    ld      A, (hex_lut, X)                 ; load the matching hex digit from the LUT: A <= hex_lut[X]
print:
    btjf    UART1_SR, #7, print             ; wait for the TX buffer to be empty
    ld      UART1_DR, A                     ; print out the character
    ret
; hex digit lookup table
hex_lut:    .ascii  "0123456789ABCDEF"
.endf

;
; Writes a null-terminated string on UART1
;
; Params:
; X - a 16-bit address of the string
;
; Clobbers:
; A, X
;
.func uart1_write_str
next_char:
    ld      A, (X)                          ; read the character at X
    jreq    exit                            ; check for null terminator, end when we're done
wait_tx_buf:
    btjf    UART1_SR, #7, wait_tx_buf       ; wait until TX buffer is empty
    ld      UART1_DR, A                     ; print out the character
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
