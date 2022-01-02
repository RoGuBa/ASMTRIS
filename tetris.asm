[bits 16]
section .text

mov es, [off_screen]

call drawBorder

call selectTetromino
call drawTetromino

;call debugDelay

call gameLoop

jmp end

gameLoop:
    tickLoop_start:
    mov bx, [move_n]
    tickLoop:
        mov ah, 0x86
        mov cx, 0
        mov dx, [tick_time]
        int 0x15
        push bx
        call check4Move
        pop bx
        dec bx
        test bx, bx
        push tickLoop_start
        jz moveTetrominoDown
        jmp tickLoop
    ret

check4Move:
    call readKeyboard
    mov ah, byte [key_scan_code]
    
    ;cmp ah, byte [key_move_down]
    ;jne c4M_down_reset
    
    c4M_press:
        cmp ah, byte [key_move_left]
        je c4M_left
        cmp ah, byte [key_move_right]
        je c4M_right
        cmp ah, byte [key_move_down]
        je c4M_down
        cmp ah, byte [key_rotate_left]
        je c4M_rotate_left
        cmp ah, byte [key_rotate_right]
        je c4M_rotate_right
        ret
    
    ;c4M_down_reset:
    ;    mov cx, [move_n_def]
    ;    mov [move_n], cx
    ;    jmp c4M_press

    c4M_left:
        mov [tetromino_move_dir], byte -1
        call moveTetrominoHor
        ret
    c4M_right:
        mov [tetromino_move_dir], byte 1
        call moveTetrominoHor
        ret
    c4M_down:
        ;mov ax, [move_n_def]
        ;shr ax, 2       ;div 4
        ;mov ax, 0
        ;mov [move_n], ax
        call moveTetrominoDown
        ret
    c4M_rotate_left:
        ret
    c4M_rotate_right:
        ;copy rotated to temp
        mov si, tetromino_current_blocks
        add si, 2               ;skip color
        mov di, tetromino_temp_blocks
        mov cx, 4
        c4m_rotate_right_loop0:
            
            mov bl, byte [si]        ;x
            inc si
            mov al, byte [si]        ;y
            neg al
            inc si
            
            mov byte [di], al
            inc di
            mov byte [di], bl
            inc di
            
            dec cx
            jnz c4m_rotate_right_loop0
        
        ;make invisible
        mov ax, 1
        call visibleTetromino
        ;check for collision
        mov [tetromino_temp_flag], word 1      ;enable temp flag
        ;mov si, tetromino_temp_blocks
        mov cx, 0
        c4M_rotate_right_loop1_0:
            mov [inW], cx
            call getTetrominoBlockPos
            call getBlock

            cmp [outW], word 0
            jne c4M_rotate_right_exit
            inc cx
            cmp cx, 4
            jb c4M_rotate_right_loop1_0
            
            ;no collision - write temp in current
            mov si, tetromino_temp_blocks
            mov di, tetromino_current_blocks
            add di, 2
            mov cx, 4
            c4M_rotate_right_loop1_1:
                mov ax, word [si]
                mov word [di], ax
                add si, 2
                add di, 2
                dec cx
                jnz c4M_rotate_right_loop1_1
        c4M_rotate_right_exit:
            ;make visible
            mov ax, 0
            call visibleTetromino
            mov [tetromino_temp_flag], word 0      ;disable temp flag
            ret


readKeyboard:
    mov ah, 0x1
    int 0x16
    jz readKeyboard_no_input
    ;found a key input
    mov byte [key_scan_code], ah
    call cmovrKeyboardBuffer
    ret
    readKeyboard_no_input:
        mov ah, byte 0
        mov byte [key_scan_code], ah
        ;cmp ah, ah                  ;not sure if needed
        ret

cmovrKeyboardBuffer:
    mov ah, 0x1
    int 0x16
    jz cmovrKeyboardBuffer_end
    ;mov [debugPrint_char], al      ;debug print ascii key
    ;call debugPrint
    mov ah, 0x0
    int 0x16
    jmp cmovrKeyboardBuffer
    cmovrKeyboardBuffer_end:
        ret

moveTetrominoHor:

    mov ax, 1
    call visibleTetromino
    
    mov cx, 0
    moveTetrominoHor_check_block:
        mov [inW], cx
        push cx
        call getTetrominoBlockPos
        pop cx
        mov al, [tetromino_move_dir]
        cbw
        add word [x_draw], ax       ;might check for pos / neg
        push cx
        call getBlock
        pop cx
        mov ax, [outW]
        cmp ax, 1
        je moveTetrominoHor_blocked
        cmp ax, 2
        je moveTetrominoHor_blocked

        inc cx
        cmp cx, 4
        jbe moveTetrominoHor_check_block

    moveTetrominoHor_move:
        mov al, [tetromino_move_dir]
        cbw
        add word [tetromino_x], ax
        call drawTetromino
        ret
    
    moveTetrominoHor_blocked:
        mov ax, 0
        call visibleTetromino
        ret

moveTetrominoDown:
    moveTetrominoDown_check:
        mov ax, 1
        call visibleTetromino           ;make invisible to not detect self
        mov cx, 0
        moveTetrominoDown_check_block:
            mov [inW], cx
            call getTetrominoBlockPos
            inc word [y_draw]   ;check block below
            call getBlock
            mov ax, [outW]
            cmp ax, 0           ;blocked by other block
            jne moveTetrominoDown_blocked
            ;cmp ax, 2           ;blocked by border
            ;je moveTetrominoDown_blocked

            inc cx
            cmp cx, 4
            jb moveTetrominoDown_check_block
    
    moveTetrominoDown_move:
        inc word [tetromino_y]
        call drawTetromino
        ret
    
    moveTetrominoDown_blocked:
    mov ax, 0
    call visibleTetromino               ;make visible
    ;spawn new
    mov [tetromino_x], word 4
    mov [tetromino_y], word 0
    call selectTetromino
    call drawTetromino
    ret

visibleTetromino:           ;ax 1->hidden 0->shown
    mov [tetromino_reset_flag], ax
    call drawTetromino
    ret

getTetrominoBlockPos:       ;inW -> block id (0-3)
                            ;tetromino_temp_flag 0 -> current 1 -> temp
                            ;ret x_draw
                            ;ret y_draw
    mov ax, [inW]
    cmp [tetromino_temp_flag], word 0
    jne getTetrominoBlockPos_temp
        mov si, tetromino_current_blocks
        add si, 2               ;skip color
    jmp getTetrominoBlockPos_current
    getTetrominoBlockPos_temp:
        mov si, tetromino_temp_blocks
    getTetrominoBlockPos_current:
    mov bx, 2
    mul bx
    add si, ax              ;add block offset
    mov al, byte [si]
    cbw
    add ax, [tetromino_x]
    mov [x_draw], ax
    
    inc si
    mov al, byte [si]
    cbw
    add ax, [tetromino_y]
    mov [y_draw], ax
    ret

selectTetromino:
    mov si, b_array_start   ;set pointer to array
    mov ax, 10
    mov bx, [tetromino_s]   ;
    mul bx                  ;
    add si, ax              ;shift pointer to selected tetromino
    
    ;copy to current_block
    mov cx, 5
    ;shr ax, 1                 ;div array_size by 2 (1 word = 2 byte)
    ;mov cx, ax
    mov di, tetromino_current_blocks    ;load mem adress
    
    selectTetromino_loop:
        mov ax, word [si]                    ;read 2 byte from [si]
        mov word [di], ax                    ;write it to [di]
        add si, 2                       ;inc si by 2
        add di, 2                       ;inc di by 2
        dec cx
        jnz selectTetromino_loop
    ret 

drawTetromino:
    mov si, tetromino_current_blocks
    mov ax, 0
    cmp [tetromino_reset_flag], ax      ;check for reset_flag
    je drawTetromino_color
    mov [tetromino_reset_flag], ax
    mov [c_draw_i], ax   ;more efficent to disable border draw
    mov [c_draw_o], ax
    add si, 2
    jmp drawTetromino_start

    drawTetromino_color:
        mov al, byte [si]
        cbw
        mov [c_draw_i], ax
        inc si
        mov al, byte [si]
        cbw
        mov [c_draw_o], ax
        inc si
    
    drawTetromino_start:
    mov cx, 4
    mov bx, [tetromino_x]
    drawTetromino_loop_0:    
        mov dx, 1
        drawTetromino_loop_1:
            mov al, byte [si]
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
                push cx                 ;
                call drawBlock          ; draw
                pop cx                  ;
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

getBlock:       ;x_draw
                ;y_draw
                ;retrun to outW   0->no block 1->block 2->border

    call getRealPos
    mov di, ax
    mov al, [es:di]
    cbw

    cmp ax, 0
    je getBlock_no_block
    cmp ax, [border_color_o]
    je getBlock_border
    
    ;block found
    mov ax, 1
    mov [outW], ax
    ret

    getBlock_border:
        mov ax, 2
        mov [outW], ax
        ret
    getBlock_no_block:
        mov ax, 0
        mov [outW], ax
        ret

getRealPos:     ;x_draw
                ;y_draw
                ;ret ax
    mov ax, [y_draw]    ;
    mul word [t_size]   ;calc real y pos
    add ax, [y_start]   ;add y start offset
    mul word [x_screen] ;multiply with screen x size
    mov bx, ax
    mov ax, [x_draw]    ;
    mul word [t_size]   ;calc real x pos
    add ax, [x_start]   ;add x start offset
    add ax, bx          ;sum all together for real x y pos
    ret

drawBlock:      ; x_draw
                ; y_draw
                ; c_draw_o
                ; c_draw_i
                ; border_flag
    
    mov ax, 0
    cmp [y_draw], ax        ;skip if block is to high
    jge drawBlock_normal
    ret

    drawBlock_normal:
       call getRealPos 
    
    ;check if border flag is 1
    mov cx, [border_flag]
    cmp cx, 0
    jz drawBlock_border_flag_skip
    mov bx, ax
    mov ax, [x_screen]
    mul word [t_size]
    add ax, [t_size]
    sub bx, ax
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


debugDelay:
    mov ah, 0x86
    mov cx, [debugDelay_time]
    mov dx, 0
    int 0x15
    ret

debugPrint:
    mov ah, 0xE
    mov al, [debugPrint_char]
    add al, 0x30
    mov bl, 10
    mov bh, 0
    int 0x10
    ret

end:
    jmp $

section .data

debugDelay_time:    dw 0xF
debugPrint_char:    dd 0

inW:        dw 0
outW:       dw 0

off_screen: dw 0xA000
x_screen:   dw 320
x_start:    dw 120 
y_start:    dw 20
t_size:     dw 8
;t_size_m1:  dw 7
t_x_size:   dw 10
t_y_size:   dw 20

tick_time:      dw 10000
tick_time_def:  dw 10000

move_n:     dw 50
move_n_def: dw 50

border_color_o: dw 18
border_color_i: dw 22

x_draw:         dw 0
y_draw:         dw 0
c_draw_i:       dw 0
c_draw_o:       dw 0
border_flag:    dw 0

tetromino_x:    dw 4
tetromino_y:    dw 3
tetromino_s:    dw 0
tetromino_reset_flag:   dw 0
tetromino_temp_flag:    dw 0


key_scan_code:      db 0
key_move_left:      db 0x4B     ;left arrow
key_move_right:     db 0x4D     ;right arrow
key_move_down:      db 0x50     ;down arrow
key_rotate_right:   db 0x20     ;d
key_rotate_left:    db 0x1E     ;a


tetromino_move_dir: db 0        ;-1 -> left  1 -> right

tetromino_current_blocks:   db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
tetromino_temp_blocks:      db 0, 0, 0, 0, 0, 0, 0, 0

;block
b_array_size:   dw 10

b_array_start:  ;(c_i, c_o), (x,y), (x,y), (x,y), (x,y)
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
b3_array:       db 0, 0, 0, -1, 1, 0, 1, -1
;b3_array_x:     db 0,  0,  1,  1
;b3_array_y:     db 0, -1,  0, -1

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

