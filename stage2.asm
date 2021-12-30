%include "stage2info.inc"
[bits 16]
[org STAGE2_RUN_OFS] ;interrupt vector table offset

;enter Graphic mode 13h 
mov ah, 0x0
mov al, 0x13
int 0x10

;disable cursor blinking
mov ax, 0x1003
mov bx, 0
mov bh, 0
int 0x10

;move cursor
mov ah, 0x2
mov bh, 0
mov dh, 1
mov dl, 1
int 0x10

;write TETRIS
mov ah, 0xE    ;tty mode 
    
    mov bl, 0x5 ;purple
    mov al, 'T'
    int 0x10
    mov al, 'E'
    int 0x10
    mov al, 'T'
    int 0x10 
    mov al, 'R'
    int 0x10
    mov al, 'I'
    int 0x10
    mov al, 'S'
    int 0x10

%include "tetris.asm"

jmp $
