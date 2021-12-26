[bits 16]
[org 0x7C00] ;interrupt vector table offsets

;enter Graphic mode 13h 
mov ah, 0x0
mov al, 0x13
int 0x10

;disable cursor blinking
mov ax, 0x1003
mov bx, 0
mov bh, 0
int 0x10

;write RGB OS with fancy colors
mov ah, 0xE    ;tty mode 

    mov al, 'R'
    mov bl, 0x4
    int 0x10

    mov al, 'G'
    mov bl, 0x2
    int 0x10

    mov al, 'B'
    mov bl, 0x1
    int 0x10
    
    mov bl, 0xF ;white
    mov al, ' '
    int 0x10
    mov al, 'O'
    int 0x10
    mov al, 'S'
    int 0x10


%include "tetris.asm"

jmp $

;make bootable
times 510-($-$$) db 0
db 0x55, 0xaa
