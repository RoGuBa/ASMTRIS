[bits 16]

mov es, [off_screen]

call drawBorder

jmp end


drawBorder:

    mov byte [x_draw], 0
    mov byte [y_draw], 0

    mov ax, [border_color_o]
    mov word [c_draw_o], ax

    mov ax, [border_color_i]
    mov [c_draw_i], ax
    
    mov [border_flag], word 1

    call drawBlock

    ;draw border around game
    
    mov [border_flag], word 0

    ret

drawBlock:      ; x_draw
                ; y_draw
                ; c_draw_o
                ; c_draw_i
                ; border_flag
    
    mov ax, [y_draw]    ;
    mul word [t_size]   ;calc real y pos
    add ax, [y_start]   ;add y start offset
    mul word [x_screen] ;multiply with screen x size
    mov bx, ax
    mov ax, [x_draw]    ;
    mul word [t_size]   ;calc real x pos
    add ax, [x_start]   ;add x start offset
    add ax, bx          ;sum all together for real x y pos
        
    mov cx, [border_flag]
    cmp cx, 0
    jz drawBlock_border_flag_skip
    
    mov bx, ax
    mov ax, [x_screen]
    mul word [t_size]
    add ax, [t_size]
    sub bx, ax
    mov ax, bx
    


    ;delay  (CX:DX)      
    mov ah, 0x86
    mov cx, 0xF
    mov dx, 0x0
    int 0x15

    mov ax, bx

    drawBlock_border_flag_skip:
    
    mov cx, [t_size]
    dec cx
    drawBlock_outer0: 
        mov dl, [c_draw_o]
        mov di, ax
        mov [es:di], dl
        
        add ax, 1
        dec cx
        jnz drawBlock_outer0        
        
        mov cx, [t_size]
        dec cx
    drawBlock_outer1:
        mov dl, [c_draw_o]
        mov di, ax         
        mov [es:di], dl
        
        add ax, [x_screen]
        dec cx
        jnz drawBlock_outer1
        
        mov cx, [t_size]
        dec cx
    drawBlock_outer2:
        mov dl, [c_draw_o]
        mov di, ax         
        mov [es:di], dl
        
        sub ax, 1
        dec cx
        jnz drawBlock_outer2
        
        mov cx, [t_size]
        dec cx
    drawBlock_outer3:
        mov dl, [c_draw_o]
        mov di, ax         
        mov [es:di], dl
        
        sub ax, [x_screen]
        dec cx
        jnz drawBlock_outer3
        
        add ax, 1
        
        mov bx, [t_size]
        dec bx
        dec bx
    drawBlock_inner0:
        mov cx, [t_size]
        dec cx
        dec cx
        add ax, [x_screen]
    drawBlock_inner1:
        mov dl, [c_draw_i]
        mov di, ax
        mov [es:di], dl
        
        add ax, 1
        dec cx
        jnz drawBlock_inner1
        
        sub ax, word [t_size]
        inc ax
        inc ax

        dec bx
        ;mov cx, bx
        jnz drawBlock_inner0

    ret


end:
    jmp $

;data section
off_screen: dw  0xA000
x_screen:   dw  320
x_start:    dw  120 
y_start:    dw  20
t_size:     dw  8
t_size_m1:  dw  7
t_x_size:   dw  10
t_y_size:   dw  20

border_color_o: dw  18
border_color_i: dw  22

x_draw:         dw 0
y_draw:         dw 0
c_draw_o:       dw 0
c_draw_i:       dw 0
border_flag:    dw 0
