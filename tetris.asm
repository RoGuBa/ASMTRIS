[bits 16]

mov es, [off_screen]

call gameLoop

call drawTetromino

call drawBorder

jmp end



gameLoop:
    
    mov bx, 20

    mov ah, 0x86
    mov cx, 0
    mov dx, 50000
    
    tickLoop:
        int 0x15
        dec bx
        jnz tickLoop
    
    mov bx, 20
    mov ah, 0x1
    int 0x16
    jz tickLoop

    ret


drawTetromino:
    ;select
    lea si, b_array_start ;set pointer to array
    mov ax, [b_array_size]
    mov bx, [tetromino_s]   ;
    mul bx                  ;
    add si, ax              ;shift pointer to selected tetromino
    
    ;color
    mov al, [si]
    cbw
    mov [c_draw_i], ax
    inc si
    mov al, [si]
    cbw
    mov [c_draw_o], ax
    inc si

    mov cx, 4
    mov bx, [tetromino_x]
    drawTetromino_loop_0:    
        mov dx, 1
        drawTetromino_loop_1:
            mov al, [si]
            cbw
            cmp ax, 0
            jl negativ
                ;positiv
                add bx, ax
                jmp next
            negativ:
                neg ax
                sub bx, ax
        next:
            inc si
            
            cmp dx, 0
            je drawTetromino_y
                ;x_value
                dec dx
                mov [x_draw], bx
                mov bx, [tetromino_y]
                jmp drawTetromino_loop_1
            drawTetromino_y:
                ;y_value
                mov [y_draw], bx
                push cx             ;
                call drawBlock      ; draw
                pop cx              ;
                mov bx, [tetromino_x]
                dec cx
                jnz drawTetromino_loop_0
    ret


drawBorder:     ;subroutine to draw border around the game
    mov word [x_draw], 0
    mov word [y_draw], 0

    mov ax, [border_color_o]
    mov word [c_draw_o], ax

    mov ax, [border_color_i]
    mov [c_draw_i], ax
        
    mov [border_flag], word 1
    
    mov cx, [t_x_size]
    inc cx
    drawBorder_0:
        push cx
        call drawBlock
        pop cx
        inc word [x_draw]
        
        dec cx
        jnz drawBorder_0
    
    mov cx, [t_y_size]
    inc cx
    drawBorder_1:
        push cx
        call drawBlock
        pop cx
        inc word [y_draw]

        dec cx
        jnz drawBorder_1
    
    mov cx, [t_x_size]
    inc cx
    drawBorder_2:
        push cx
        call drawBlock
        pop cx
        dec word [x_draw]

        dec cx
        jnz drawBorder_2
    
    mov cx, [t_y_size]
    inc cx
    drawBorder_3:
        push cx
        call drawBlock
        pop cx
        dec word [y_draw]

        dec cx
        jnz drawBorder_3

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
;t_size_m1:  dw  7
t_x_size:   dw  10
t_y_size:   dw  20

move_n:     dw  10

border_color_o: dw  18
border_color_i: dw  22

x_draw:         dw 0
y_draw:         dw 0
c_draw_i:       dw 0
c_draw_o:       dw 0
border_flag:    dw 0

tetromino_x:    dw 2
tetromino_y:    dw 5
tetromino_s:    dw 1 

;block
b_array_size:   dw 10

b_array_start:  ;(c_o, c_i), (x,y), (x,y), (x,y), (x,y)
;----   (0)
b0_color:       db 0x34, 0x35
b0_array:       db -1, 0, 0, 0, 1, 0, 2, 0
;b0_array_x:     db -1,  0,  1,  2
;b0_array_y:     db  0,  0,  0,  0

;-
;---    (1)
b1_color:       db 0x21, 0x01
b1_array:       db -1, -1, -1, 0, 0, 0, 1, 0
;b1_array_x:     db -1, -1,  0,  1
;b1_array_y:     db -1,  0,  0,  0

;  -
;---    (2)
b2_color:       db 0x2A, 0x29
b2_array:       db -1, 0, 0, 0, 1, 0, 1, -1
;b2_array_x:     db -1,  0,  1,  1
;b2_array_y:     db  0,  0,  0, -1

;--
;--     (3)
b3_color:       db 0x2C, 0x2B
b3_array:       db -1, -1, 0, -1, -1, 0, 0, 0
;b3_array_x:     db -1,  0, -1,  0
;b3_array_y:     db -1, -1,  0,  0

; --
;--     (4)
b4_color:       db 0x30, 0x77
b4_array:       db -1, 1, 0, 1, 0, 0, 1, 0
;b4_array_x:     db -1,  0,  0,  1
;b4_array_y:     db  1,  1,  0,  0

; -
;---    (5)
b5_color:       db 0x23, 0x6B
b5_array:       db -1, 0, 0, 0, 0, -1, 1, 0
;b5_array_x:     db -1,  0,  0,  1
;b5_array_y:     db  0,  0, -1,  0

;--
; --    (6)
b6_color:       db 0x28, 0x70
b6_array:       db -1, 0, 0, 0, 0, 1, 1, 1
;b6_array_x:     db -1,  0,  0,  1
;b6_array_y:     db  0,  0,  1,  1

