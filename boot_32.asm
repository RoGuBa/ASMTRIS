[org 0x7C00] ;interrupt vector table offsets

;enter Graphic mode 13 320x200 VGA 256 color
mov ah, 0x0
mov al, 0x13
int 0x10

;disable cursor blinking
mov ax, 0x1003
mov bx, 0
mov bh, 0
int 0x10

CODE_SEG equ GDT_code - GDT_start
DATA_SEG equ GDT_data - GDT_start

;enable A20
in al, 0x92
or al, 2
out 0x92, al

cli
lgdt [GDT_descriptor]
mov eax, cr0
or eax, 0x1
mov cr0, eax
jmp CODE_SEG:start_32_bit_protected_mode

GDT_start:
    GDT_null:    ;16byte 0s
        dd 0x0
        dd 0x0
    GDT_code:
        dw 0xffff       ;first 16 bits of limit
        dw 0x0          ;fist 24 bits of base
        db 0x0          ;
        db 0b10011010   ;flags
        db 0b11001111   ;other flags + limit
        db 0x0          ;last 8 bits of base
    GDT_data:
        dw 0xffff
        dw 0x0
        db 0x0
        db 0b10010010
        db 0b11001111
        db 0x0
GDT_end:

GDT_descriptor:
    dw GDT_end - GDT_start -1   ;size
    dd GDT_start                ;start

[bits 32]
start_32_bit_protected_mode:

;    %include "tetris.asm"
;    jmp tetris_start

jmp $

;make bootable
times 510-($-$$) db 0
dw 0xaa55
