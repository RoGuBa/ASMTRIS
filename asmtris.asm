[bits 16]

section .text

mov es, [off_screen]

;timer mem adress
mov ax, 0x0
mov fs, ax

start:

call init

call drawBorder
call drawBackground

call debugDelay

call spawnTetromino

mov ax, [move_n_def]
mov [move_n], ax

call gameLoop

jmp end

init:    
    ;enter video mode 13h (clear screen)
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

    ;write ASMTRIS
    mov ah, 0xE     ;tty mode
    mov bl, 0x5     ;purple

    mov bl, 0x5 ;purple
    mov al, 'A'
    int 0x10
    mov al, 'S'
    int 0x10
    mov al, 'M'
    int 0x10
    mov al, 'T'
    int 0x10
    mov al, 'R'
    int 0x10
    mov al, 'I'
    int 0x10
    mov al, 'S'
    int 0x10
    
    ret

gameLoop:
    tickLoop_start:
    mov cx, [move_n]
    tickLoop:
        push cx
        mov ah, 0x86
        mov cx, 0
        mov dx, [tick_time]
        int 0x15
        ;keyboard input
        call readKeyboard
        call check4AdminKeys
        call check4Move
        pop cx
        dec cx
        loop tickLoop
        call moveTetrominoDown
        jmp tickLoop_start
    ret

check4AdminKeys:
    mov ah, byte [key_scan_code]
    cmp ah, byte [key_restart]
    je c4A_restart
    ret
    c4A_restart:
        ;clear return and bx from loop form stack
        pop ax
        pop ax
        ;restart
        jmp start


checkFullLine:
    ;start check at lowest line
    mov cx, [t_y_size]
    checkFullLine_y_loop:
        dec cl
        cmp cl, 0
        jl checkFullLine_end
        mov bl, [t_x_size]
        checkFullLine_x_loop:
            dec bl
            mov [x_draw], bl
            mov [y_draw], cl
            push bx
            call getBlock
            pop bx
            cmp [outW], word 0          ;check if ther is a free block
            je checkFullLine_y_loop     ;if so check next line
            cmp bl, 0                   ;else check next block in line
            jge checkFullLine_x_loop
            jmp clearFullLine           ;full line if no block is free
        cmp cl, 0
        jge checkFullLine_y_loop
    checkFullLine_end:
    ret

clearFullLine:
    ;clear
    mov ax, [background_color]
    mov [c_draw_i], ax
    mov [c_draw_o], ax
    xor cx, cx
    mov cl, [t_x_size]
    clearFullLine_loop:
        dec cl
        mov [x_draw], cl
        push cx
        call drawBlock
        pop cx
        cmp cl, 0
        jg clearFullLine_loop
    
    ;move every line above one down
    xor cx, cx
    xor bx, bx
    mov cl, [y_draw]
    moveLineDown_y_loop:
        dec cl
        mov [y_draw], cl
        mov bl, [t_x_size]
        moveLineDown_x_loop:
            dec bl
            mov [x_draw], bl
            push cx
            call getColor
            pop cx
            inc cl
            mov [y_draw], cl
            dec cl
            push cx
            call drawBlock
            pop cx
            mov [y_draw], cl
            mov bl, [x_draw]
            cmp bl, 0
            jg moveLineDown_x_loop
        cmp cl, 0
        jg moveLineDown_y_loop
    jmp checkFullLine

check4Move:
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
        je c4M_rotate
        cmp ah, byte [key_rotate_right]
        je c4M_rotate
        cmp ah, byte [key_rotate_right_0]
        je c4M_rotate
        cmp ah, byte [key_hold]
        je c4M_hold
        ret
    
    ;c4M_down_reset:
    ;    mov cx, [move_n_def]
    ;    mov [move_n], cx
    ;    jmp c4M_press
    
    c4M_hold:
        cmp [hold_used_flag], byte 1
        je c4M_hold_skip
        
        call drawHoldTetromino
        mov [hold_used_flag], byte 1        ;set hold used for this block
        
        mov ax, 1
        call visibleTetromino               ;make invisible
        
        mov si, hold_tetromino_blocks
        mov di, tetromino_current_blocks
        
        mov cx, [b_array_size]
        shr cx, 1               ;div 2
        
        c4M_hold_loop:
            mov ax, [si]
            mov bx, [di]

            mov [di], ax
            mov [si], bx

            add si, 2
            add di, 2
        loop c4M_hold_loop
        
        call drawHoldTetromino
         
        mov ax, [tetromino_rotate_flag]         ;copy rotate flag
        mov bx, [hold_tetromino_rotate_flag]
        mov [hold_tetromino_rotate_flag], ax
        mov [tetromino_rotate_flag], bx

        cmp byte [hold_full_flag], byte 0
        je c4M_hold_new
        
        mov al, [tetromino_x_start]
        mov [tetromino_x], al
        mov al, [tetromino_y_start]
        mov [tetromino_y], al

        mov byte [hold_full_flag], byte 1
        mov ax, 0
        call visibleTetromino
               
        ret
        c4M_hold_new:
        mov byte [hold_full_flag], byte 1
        call spawnTetromino
        mov [hold_used_flag], byte 1
        ret

        c4M_hold_skip:
        ret

    c4M_left:
        mov [tetromino_move_dir], word 1
        call moveTetrominoHor
        ret
    c4M_right:
        mov [tetromino_move_dir], word 0
        call moveTetrominoHor
        ret
    c4M_down:
        ;mov ax, [move_n_def]
        ;shr ax, 2       ;div 4
        ;mov ax, 0
        ;mov [move_n], ax
        call moveTetrominoDown
        ret

    c4M_rotate:
        ;check rotate flag
        mov ax, [tetromino_rotate_flag]
        cmp ax, 2
        jb c4M_rotate_start     ;I -> [tetromino_rotate_flag] = 1 (todo)
        ret                     ;[tetromino_roate_flag] = 2
        
        c4M_rotate_start:
            ;copy rotated to temp
            mov si, tetromino_current_blocks
            add si, 2               ;skip color
            mov di, tetromino_temp_blocks
            mov cx, 4
            c4M_rotate_loop:
                mov al, byte [si]       ;x
                inc si
                mov bl, byte [si]       ;y
                inc si
                cmp ah, byte [key_rotate_left]
                je c4M_rotate_left
                    neg bl
                    jmp c4M_rotate_right
                c4M_rotate_left:
                    neg al
                c4M_rotate_right:
                mov byte [di], bl
                inc di
                mov byte [di], al
                inc di
                
                loop c4M_rotate_loop
            jmp c4M_rotate_check

c4M_rotate_check:
    ;make invisible
    mov ax, 1
    call visibleTetromino
    ;check for collision
    mov [tetromino_temp_flag], word 1      ;enable temp flag  
    mov cx, 4
    c4M_rotate_loop0:
        mov [inW], cx
        call getTetrominoBlockPos
        call getBlock

        cmp [outW], word 0
        jne c4M_rotate_exit
        loop c4M_rotate_loop0
        
        ;no collision - write temp in current
        mov si, tetromino_temp_blocks
        mov di, tetromino_current_blocks
        add di, 2
        mov cx, 4
        c4M_rotate_loop1:
            mov ax, word [si]
            mov word [di], ax
            add si, 2
            add di, 2
            loop c4M_rotate_loop1
    c4M_rotate_exit:
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
    call clearKeyboardBuffer
    ret
    readKeyboard_no_input:
        mov ah, byte 0
        mov byte [key_scan_code], ah
        ret

clearKeyboardBuffer:
    mov ah, 0x1
    int 0x16
    jz clearKeyboardBuffer_end
    ;mov [debugPrint_char], al      ;debug print ascii key
    ;call debugPrint
    mov ah, 0x0
    int 0x16
    jmp clearKeyboardBuffer
    clearKeyboardBuffer_end:
        ret

moveTetrominoHor:
    mov ax, 1
    call visibleTetromino 
    mov cx, 4
    moveTetrominoHor_check_block:
        mov [inW], cx
        push cx
        call getTetrominoBlockPos
        mov ax, [tetromino_move_dir]
        cmp ax, 1
        je moveTetrominoHor_left
            add [x_draw], byte 2
        moveTetrominoHor_left:
            sub [x_draw], byte 1

        pop cx
        call getBlock
        mov ax, [outW]
        cmp ax, 1
        je moveTetrominoHor_blocked
        cmp ax, 2
        je moveTetrominoHor_blocked

        loop moveTetrominoHor_check_block

    moveTetrominoHor_move:
        mov ax, [tetromino_move_dir]
        cmp ax, 1
        je moveTetrominoHor_move_left
            add [tetromino_x], byte 2
        moveTetrominoHor_move_left:
            sub [tetromino_x], byte 1
        call drawTetromino
        ret
    
    moveTetrominoHor_blocked:
        mov ax, 0
        call visibleTetromino
        ret

moveTetrominoDown:
    mov ax, 1
    call visibleTetromino           ;make invisible to not detect self
    mov cx, 4
    moveTetrominoDown_check_block:
        mov [inW], cx
        call getTetrominoBlockPos
        inc byte [y_draw]   ;check block below
        call getBlock
        mov ax, [outW]
        cmp ax, 0           ;blocked by other block
        jne moveTetrominoDown_blocked
        ;cmp ax, 2           ;blocked by border
        ;je moveTetrominoDown_blocked

        loop moveTetrominoDown_check_block

    moveTetrominoDown_move:
        inc word [tetromino_y]
        call drawTetromino
        ret
    
    moveTetrominoDown_blocked:
    mov ax, 0
    call visibleTetromino               ;make visible
    ;check full line
    call checkFullLine
    ;spawn new
    call spawnTetromino
    ret

visibleTetromino:           ;ax 1->hidden 0->shown
    mov [tetromino_reset_flag], ax
    call drawTetromino
    ret

getTetrominoBlockPos:       ;inW -> block id (1-4)
                            ;tetromino_temp_flag 0 -> current 1 -> temp
                            ;ret x_draw
                            ;ret y_draw
    mov ax, [inW]
    dec ax
    cmp [tetromino_temp_flag], word 0
    jne getTetrominoBlockPos_temp
        mov si, tetromino_current_blocks
        add si, word 2      ;skip color
        jmp getTetrominoBlockPos_current
    getTetrominoBlockPos_temp:
        mov si, tetromino_temp_blocks
    getTetrominoBlockPos_current:
    add ax, ax
    add si, ax              ;add block offset
    xor ax, ax
    xor bx, bx
    mov al, byte [si]
    mov bl, [tetromino_x]
    
    cmp al, 0
    jl getTetrominoBlockPos_neg_x
        add bl, al
        jmp getTetrominoBlockPos_pos_x
    getTetrominoBlockPos_neg_x:
        neg al
        sub bl, al
    getTetrominoBlockPos_pos_x:
    mov [x_draw], bl
    inc si
    xor ax, ax
    xor bx, bx
    mov al, byte [si]
    mov bl, [tetromino_y]
    cmp al, 0
    jl getTetrominoBlockPos_neg_y
        add bl, al
        jmp getTetrominoBlockPos_pos_y
    getTetrominoBlockPos_neg_y:
        neg al
        sub bl, al
    getTetrominoBlockPos_pos_y:
    mov [y_draw], bl
    ret

getRandomTetromino:
    mov di, [off_timer]
    xor ax, ax                  ;clear ax
    mov ax, [fs:di]             ;write 2bytes of timer counter into ax
    xor dx, dx                  ;clear dx (needed for %)
    mov bx, 7                   ;
    div bx                      ;div by 7
    mov [tetromino_s], byte dl  ;write remainder into [tetromino_s]
    cmp dl, 0
    je getRandomTetrominoIRotation
    cmp dl, 3
    je getRandomTetrominoDisableRotation
    xor ax, ax                  ;normal rotation
    jmp getRandomTetrominoEnd
    getRandomTetrominoIRotation:
        mov ax, 1               ;rotation for I tetromino
        jmp getRandomTetrominoEnd
    getRandomTetrominoDisableRotation:
        mov ax, 2               ;no rotation
        jmp getRandomTetrominoEnd
    getRandomTetrominoEnd:
        mov [tetromino_rotate_flag], ax
        ret

spawnTetromino:
    mov al, [tetromino_x_start]
    mov [tetromino_x], al
    mov al, [tetromino_y_start]
    mov [tetromino_y], al
    mov [hold_used_flag], byte 0
    call selectTetromino
    call drawTetromino
    ret 

selectTetromino:
    call getRandomTetromino
    mov si, b_array_start           ;set pointer to array
    mov ax, 10
    mov bl, [tetromino_s]           ;
    mul bl                          ;
    add si, ax                      ;shift pointer to selected tetromino
    
    ;copy to current_block
    mov cx, [b_array_size]
    shr cx, 1                               ;div array_size by 2 (1 word = 2 byte)
    mov di, tetromino_current_blocks        ;load mem adress
    selectTetromino_loop:
        mov ax, word [si]                   ;read 2 byte from [si]
        mov word [di], ax                   ;write it to [di]

        add si, 2                           ;inc si by 2
        add di, 2                           ;inc di by 2
        loop selectTetromino_loop
    ret 

drawTetromino:
    mov si, tetromino_current_blocks
    mov ax, 0
    cmp [tetromino_reset_flag], ax      ;check for reset_flag
    je drawTetromino_color
    mov [tetromino_reset_flag], ax      ;reset flag to 0
    mov ax, [background_color]
    mov [c_draw_i], ax   ;more efficent to disable border draw
    mov [c_draw_o], ax
    add si, 2
    jmp drawTetromino_start

    drawTetromino_color:
        xor ax, ax
        mov al, byte [si]
        mov [c_draw_i], ax
        inc si
        xor ax, ax
        mov al, byte [si]
        mov [c_draw_o], ax
        inc si
    
    drawTetromino_start:
    mov cx, 4
    mov bl, [tetromino_x]
    drawTetromino_loop_0:    
        mov dx, 1
        drawTetromino_loop_1:
            mov al, byte [si]
            cmp al, 0
            jl drawTetromino_neg
                ;positiv
                add bl, al
                jmp drawTetromino_next
            drawTetromino_neg:
                neg al
                sub bl, al
        drawTetromino_next:
            inc si
            
            cmp dx, 0
            je drawTetromino_y
                ;x_value
                dec dx
                mov [x_draw], bl
                mov bl, [tetromino_y]
                jmp drawTetromino_loop_1
            drawTetromino_y:
                ;y_value
                mov [y_draw], bl
                push cx                 ;
                call drawBlock          ; draw
                pop cx                  ;
                mov bl, [tetromino_x]
                dec cx
                jnz drawTetromino_loop_0
        ret

drawHoldTetromino:
    mov si, hold_tetromino_blocks
    
    cmp [hold_used_flag], byte 0
    je drawHoldTetromino_clear
    ;color
    xor ax, ax
    mov al, byte [si]
    mov [c_draw_i], ax
    inc si
    xor ax, ax
    mov al, byte [si]
    mov [c_draw_o], ax
    inc si
    jmp drawHoldTetromino_start
    drawHoldTetromino_clear:
        add si, 2
        mov ax, [background_color]
        mov [c_draw_i], ax
        mov [c_draw_o], ax
    drawHoldTetromino_start:
    mov [draw_flag], word 2
    xor bx, bx
    mov cx, 4
    drawHoldTetromino_loop:
        mov bl, 3
        mov al, byte [si]
        cmp al, 0
        jl drawHoldTetromino_x_neg
            ;pos
            add bl, al
            jmp drawHoldTetromino_x_next
        drawHoldTetromino_x_neg:
            ;neg
            neg al
            sub bl, al
        drawHoldTetromino_x_next:
        mov [x_draw], byte bl
        inc si
        mov bl, 3
        mov al, byte [si]
        cmp al, 0
        jl drawHoldTetromino_y_neg
            ;pos
            add bl, al
            jmp drawHoldTetromino_y_next
        drawHoldTetromino_y_neg:
            ;neg
            neg al
            sub bl, al
        drawHoldTetromino_y_next:
        mov [y_draw], byte bl
        inc si
        push cx
        call drawBlock
        pop cx
    loop drawHoldTetromino_loop
    
    mov [draw_flag], word 0
    
    ret

drawBorder:     ;subroutine to draw border around the game
    mov byte [x_draw], 0
    mov byte [y_draw], 0

    mov ax, [border_color_o]
    mov word [c_draw_o], ax

    mov ax, [border_color_i]
    mov [c_draw_i], ax
        
    mov [draw_flag], word 2
    push word [t_x_size]
    push word [t_y_size]
    
    mov ax, [x_hold_size]
    mov [t_x_size], ax
    
    mov ax, [y_hold_size]
    mov [t_y_size], ax
    
    mov cx, 2
    drawBorder_loop:
    cmp cx, 1
    jne drawBorder_loop_hold
        pop word [t_y_size]
        pop word [t_x_size]
        mov [draw_flag], word 1
    drawBorder_loop_hold:
    push cx

        mov cx, [t_x_size]
        inc cx
        drawBorder_0:
            push cx
            call drawBlock
            pop cx
            inc byte [x_draw]
            
            dec cx
            jnz drawBorder_0
        
        mov cx, [t_y_size]
        inc cx
        drawBorder_1:
            push cx
            call drawBlock
            pop cx
            inc byte [y_draw]

            dec cx
            jnz drawBorder_1
        
        mov cx, [t_x_size]
        inc cx
        drawBorder_2:
            push cx
            call drawBlock
            pop cx
            dec byte [x_draw]

            dec cx
            jnz drawBorder_2
        
        mov cx, [t_y_size]
        inc cx
        drawBorder_3:
            push cx
            call drawBlock
            pop cx
            dec byte [y_draw]

            dec cx
            jnz drawBorder_3
        
        pop cx
        loop drawBorder_loop
    
    mov [draw_flag], word 0
    ret

drawBackground:
    mov ax, [background_color]
    mov [c_draw_o], ax
    mov [c_draw_i], ax
    mov [draw_flag], word 2

    mov ax, [t_x_size]
    push ax
    mov ax, [t_y_size]
    push ax
    
    mov ax, [x_hold_size]
    mov [t_x_size], ax
    mov ax, [y_hold_size]
    mov [t_y_size], ax

    mov cx, 2
    drawBackground_loop:
        cmp cx, 1
        jne drawBackground_loop_hold
            pop word [t_y_size]
            pop word [t_x_size]
            mov [draw_flag], word 1
        drawBackground_loop_hold:
        push cx
        
        mov cx, [t_x_size]
        drawBackground_x:
            mov [x_draw], cl
            push cx
            mov cx, [t_y_size]
            drawBackground_y:
                mov [y_draw], cl
                push cx
                call drawBlock
                pop cx
            loop drawBackground_y
            pop cx
        loop drawBackground_x
        pop cx
        loop drawBackground_loop
    mov [draw_flag], word 0
    ret

getColor:       ;x_draw
                ;y_draw
                ;ret c_draw_i
                ;ret c_draw_o
    call getRealPos
    mov di, ax
    xor ax, ax
    mov al, [es:di]
    
    mov [c_draw_o], ax

    add di, [x_screen]  ;one down
    add di, 1           ;one to the left
    mov al, [es:di]
    cbw

    mov [c_draw_i], ax
    
    ret

getBlock:       ;x_draw
                ;y_draw
                ;retrun to outW   0->no block 1->block 2->border
    cmp [x_draw], byte 0
    jl getBlock_border
    call getRealPos
    mov di, ax
    xor ax, ax
    mov al, [es:di]
    
    cmp ax, [background_color]
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
    xor ax, ax
    mov al, [y_draw]
    mul byte [t_size]   ;calc real y pos
    add ax, [y_start]   ;add y start offset
    mul word [x_screen] ;multiply with screen x size
    mov bx, ax
    xor ax, ax
    mov al, [x_draw]    ;
    mul word [t_size]   ;calc real x pos
    add ax, [x_start]   ;add x start offset
    add ax, bx          ;sum all together for real x y pos
    ret

drawBlock:      ; x_draw
                ; y_draw
                ; c_draw_o
                ; c_draw_i
                ; draw_flag 0 -> normal, 1 -> border, 2 -> holdBorder
    
    mov al, 0
    cmp [y_draw], al        ;skip if block is to high
    jge drawBlock_normal
    ret

    drawBlock_normal:
    call getRealPos 
    
    ;check draw flag
    mov cx, [draw_flag]
    cmp cx, 0
    je drawBlock_draw_flag_skip
    cmp cx, 1
    je drawBlock_draw_flag_border
    cmp cx, 2
    je drawBlock_draw_flag_hold_border
    jmp drawBlock_draw_flag_skip
    
    drawBlock_draw_flag_border:
        mov bx, ax
        mov ax, [x_screen]
        mul word [t_size]
        add ax, [t_size]
        sub bx, ax
        mov ax, bx
        jmp drawBlock_draw_flag_skip
    
    drawBlock_draw_flag_hold_border:
        mov bx, ax
        mov ax, [t_size]
        mov cx, [x_hold_size]
        inc cx
        mul cx
        mov cx, ax
        mov ax, [x_screen]
        mul word [t_size]
        add ax, [t_size]
        add ax, cx
        sub bx, ax
        mov ax, bx
        jmp drawBlock_draw_flag_skip
    drawBlock_draw_flag_skip:

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
y_screen:   dw 200
x_start:    dw 120 
y_start:    dw 20
t_size:     dw 8
t_x_size:   dw 10
t_y_size:   dw 20

off_timer:  dw 0x46C
bit_mask_timer: db 0b00000111

tick_time_def:  dw 10000
tick_time:      dw 10000

move_n_def: dw 40
move_n:     dw 40

border_color_o: dw 0x12
border_color_i: dw 0x16

x_hold_size:    dw 5
y_hold_size:    dw 5

background_color: dw 0x0

x_draw:         db 0
y_draw:         db 0
c_draw_i:       dw 0
c_draw_o:       dw 0
draw_flag:      dw 0

tetromino_x_start:  db 4
tetromino_y_start:  db 0
tetromino_x:    db 4
tetromino_y:    db 0
tetromino_s:    db 1
tetromino_reset_flag:   dw 0
tetromino_temp_flag:    dw 0
tetromino_rotate_flag:  dw 0

key_scan_code:      db 0
key_move_left:      db 0x4B     ;left arrow
key_move_right:     db 0x4D     ;right arrow
key_move_down:      db 0x50     ;down arrow
key_rotate_right:   db 0x20     ;d
key_rotate_right_0: db 0x48     ;up arrow
key_rotate_left:    db 0x1E     ;a
key_restart:        db 0x13     ;r
key_hold:           db 0x11     ;w

hold_used_flag:     db 0
hold_full_flag:     db 0

hold_tetromino_blocks:      db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
hold_tetromino_rotate_flag: dw 0

tetromino_move_dir: dw 0        ;1 -> left  0 -> right

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

