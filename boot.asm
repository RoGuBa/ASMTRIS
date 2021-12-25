
mov ah, 0x0e    ;tty mode
mov al, 'R'
int 0x10        ;interrupt vector 0x10

mov al, 'G'
int 0x10

mov al, 'B'
int 0x10

;make bootable
jmp $
times 510-($-$$) db 0
db 0x55, 0xaa

