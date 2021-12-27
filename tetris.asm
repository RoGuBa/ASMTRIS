[bits 16]

;delay  (CX:DX)
mov ah, 0x86
mov cx, 0xF
mov dx, 0x0

int 0x15

mov ax, 0x0A000
mov es, ax
mov dl, 7


mov ax, 0
mov di, ax
mov [es:di], dl


mov ax, 50
mov bx, 50


drawRect:       ;ax -> y start (vertical)
                ;bx -> x start (horizontal)
    mov cx, 320
    mul cx
    add ax, bx
    mov di, ax
    
    mov bx, 8
dR_loop:
    cmp bx, 0
    ja dR_loop_b
    jmp drawRect_end
    
dR_loop_b:
    dec bx
    add ax, 312     ;320-8
    mov cx, 8
dR_loop_c:
    dec cx
    add ax, 1
    mov di, ax
    mov dl, 7
    mov [es:di], dl

    cmp cx, 0
    ja dR_loop_c
    jmp dR_loop

drawRect_end:
