[bits 16]

section .data

tmp1    dw    0
tmp2    dw    0
tmp3    db    0
tmp4    db    0

section .text

;delay  (CX:DX)
mov ah, 0x86
mov cx, 0xF
mov dx, 0x0
int 0x15


mov ax, 0x0A000
mov es, ax
mov dl, 7



mov al, 5
mov [tmp3], al
mov ax, 50
mov bx, 50
call drawRect


;mov ax, 58
;mov bx, 58
;call drawRect


call tick


jmp end

drawRect:       ;ax -> y start (vertical)
                ;bx -> x start (horizontal)
                ;tmp3 -> color
    mov cx, 320
    dec ax
    mul cx
    add ax, bx
    add ax, 7
    mov di, ax
    
    mov bx, 8
dR_loop:
    cmp bx, 0
    ja dR_loop_b
    ret
    
dR_loop_b:
    dec bx
    add ax, 312     ;320-8
    mov cx, 8
dR_loop_c:
    dec cx
    add ax, 1
    mov di, ax
    mov dl, [tmp3]
    mov [es:di], dl

    cmp cx, 0
    ja dR_loop_c
    jmp dR_loop


one_down:           ;tmp1 -> x
                    ;tmp2 -> y
                    ;tmp4 -> color

    mov al, 0
    mov [tmp3], al
    mov ax, [tmp2]
    mov bx, [tmp1]

    call drawRect
   
    mov al, 5
    mov [tmp3], al
    mov ax, [tmp1]
    add ax, 8
    mov bx, [tmp2]
    call drawRect

    ret

tick:
    ;delay  (CX:DX)
    mov ah, 0x86
    mov cx, 0xF
    mov dx, 0x0
    int 0x15
    
    ;check for block and move 1 down

    mov ah, 0x0D
    mov bh, 0x0
    mov cx, 50
    mov dx, 50
    int 0x10
    
    mov [tmp1], dx
    mov [tmp2], cx
    mov [tmp4], al

    call one_down 

    ret

end:
