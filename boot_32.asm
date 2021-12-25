[org 0x7C00] ;interrupt vector table offsets

CODE_SEG equ GDT_code - GDT_start
DATA_SEG equ GDT_data - GDT_start

cli
lgdt [GDT_descriptor]
mov eax, cr0
or eax, 1
mov cr0, eax
jmp CODE_SEG:start_32_bit_protected_mode

jmp $

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
    
    mov al, 'A'
    mov ah, 0x0f
    mov [0xb8000], ax

jmp $

;make bootable
times 510-($-$$) db 0
dw 0xaa55
