.stm8
;
; STM8 SPI assembly routines test program.
; Best viewed with a logic analyzer ;-)
;

.include "chips/stm8s103.inc"
.include "macros/data.inc"

; CS pin on port A
CS equ 3

; RAM variables
DATA_START(RAM_START)

DATA(rx_buffer1, 32)
DATA(rx_buffer2, 32)

; code start
.org CODE_START

.include "functions/byte_to_hex.inc"
.include "functions/spi_recv_buf.inc"
.include "functions/spi_send_buf.inc"
.include "functions/spi_xmit.inc"
.include "functions/spi_xmit_buf.inc"
.include "functions/uart1_write_str.inc"

; strings
str_hello:      .asciiz "Hello World!"
str_recv_buf:   .asciiz "spi_recv_buf: "
str_xmit:       .asciiz "spi_xmit: 0x"
str_xmit_buf:   .asciiz "spi_xmit_buf: "

start:
    mov     CLK_CKDIVR, #0x00               ; clock setup (16MHz from HSI)
                                            ; UART setup (note that UART is by default already in 8n1 mode)
    mov     UART1_BRR2, #0x0b               ; Set the baud rate to 115200 bps, BRR2 needs to be set first
    mov     UART1_BRR1, #0x08               ;
    bset    UART1_CR2, #3                   ; Enable UART transmitter

    bset    PA_DDR, #CS                     ; Set the CS line to output
    bset    PA_CR1, #CS                     ; Set the CS line to push-pull mode
    bset    PA_ODR, #CS                     ; Set the CS line to high

    mov     SPI_CR1, #(0x0 << 3)            ; Set baud rate control
    mov     SPI_CR2, #0x3                   ; Set SSM and SSI
    bset    SPI_CR1, #2                     ; Set SPI to master mode
    bset    SPI_CR1, #6                     ; Enable SPI

    bres    PA_ODR, #CS                     ; Reset the CS line
    ld      A, #0xAA                        ; Load the data byte
    call    spi_xmit                        ; Transmit it (and simultanously receive a response)
    bset    PA_ODR, #CS                     ; Set the CS line
    push    A                               ; Store the received byte

    call    print_crlf
    call    print_spi_sr                    ; Print the SPI_SR contents

    ldw     X, #str_xmit                    ; Print the received byte
    call    uart1_write_str
    pop     A
    call    print_hex_byte
    call    print_crlf

    bres    PA_ODR, #CS                     ; Reset the CS line

    ld      A, #13                          ; Load the data length
    ldw     X, #str_hello                   ; Load the TX buffer address
    ldw     Y, #rx_buffer1                  ; Load the RX buffer address
    call    spi_xmit_buf                    ; Transmit/receive the data

    ld      A, #13                          ; Load the data length
    ldw     X, #str_hello                   ; Load the TX buffer address
    call    spi_send_buf                    ; Transmit-only the data

    ld      A, #13                          ; Load the data length
    ldw     X, #rx_buffer2                  ; Load the RX buffer address
    call    spi_recv_buf                    ; Receive-only the data (should transmit zeroes)

    bset    PA_ODR, #CS                     ; Set the CS line

    call    print_spi_sr                    ; Print the SPI_SR contents

    ldw     X, #str_xmit_buf                ; Print the data received by str_xmit_buf
    call    uart1_write_str
    ld      A, #13
    ldw     X, #rx_buffer1
    call    print_hex_buf
    call    print_crlf

    ldw     X, #str_recv_buf                ; Print the data received by str_recv_buf
    call    uart1_write_str
    ld      A, #13
    ldw     X, #rx_buffer2
    call    print_hex_buf
    call    print_crlf

end:
    jp end                                  ; loop forever

;
; Dumps the SPI_SR register
;
.func print_spi_sr
    ldw     X, #str_spi_sr                  ; Load the title string address
    call    uart1_write_str                 ; Print it
    ld      A, SPI_SR                       ; Load the status register
    call    print_hex_byte                  ; Print it in hex format
    call    print_crlf                      ; Print the final new-line
    ret
str_spi_sr:     .asciiz "SPI_SR: 0x"
.endf

;
; Prints a new-line sequence (CRLF)
;
.func print_crlf
    ldw     X, #crlf                        ; Load the sequence address
    call    uart1_write_str                 ; Print it
    ret
crlf:       .asciiz "\r\n"
.endf

;
; Prints contents of the provided buffer in hex format
;
; Params:
; A - data length
; X - buffer
;
.func print_hex_buf
    push    A                               ; Save the data length on stack
next:
    ld      A, (X)                          ; Load the first data byte
    pushw   X                               ; Save the data address on stack
    call    print_hex_byte                  ; Print the byte
    popw    X                               ; Restore the data address
    incw    X                               ; Increment it
    dec     (1, SP)                         ; Decrement the data length
    jrne    next                            ; Print next if any
    pop     A                               ; Stack cleanup
    ret
.endf

;
; Prints a hexadecimal represention of a byte
;
; Params:
; A - byte to print
;
.func print_hex_byte
    call    byte_to_hex                     ; Convert the value to hex
    ld      A, XH                           ; Load the first hex digit
    ld      UART1_DR, A                     ; Write it out
    btjf    UART1_SR, #7, $                 ; Wait for the transmit register to be empty
    ld      A, XL                           ; Load the second hex digit
    ld      UART1_DR, A                     ; Write it out
    btjf    UART1_SR, #7, $                 ; Wait for the transmit register to be empty
    btjf    UART1_SR, #6, $                 ; wait for the transmission to complete
    ret
.endf

; interrupt vectors
.org VECTORS_START
    int start                               ; RESET handler, jump to the main program body
