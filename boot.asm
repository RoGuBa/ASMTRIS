%include "stage2info.inc"

STAGE2_LOAD_SEG  equ STAGE2_ABS_ADDR>>4
                                ; Segment to start reading Stage2 into
                                ;     right after bootloader

STAGE2_LBA_START equ 1          ; Logical Block Address(LBA) Stage2 starts on
                                ;     LBA 1 = sector after boot sector
STAGE2_LBA_END   equ STAGE2_LBA_START + NUM_STAGE2_SECTORS
                                ; Logical Block Address(LBA) Stage2 ends at
DISK_RETRIES     equ 3          ; Number of times to retry on disk error

bits 16
ORG 0x7c00

; Include a BPB (1.44MB floppy with FAT12) to be more comaptible with USB floppy media
%include "bpb.inc"

boot_start:
    xor ax, ax                  ; DS=SS=ES=0 for stage2 loading
    mov ds, ax
    mov ss, ax                  ; Stack at 0x0000:0x7c00
    mov sp, 0x7c00
    cld                         ; Set string instructions to use forward movement

    ; Read Stage2 1 sector at a time until stage2 is completely loaded
load_stage2:
    mov [bootDevice], dl        ; Save boot drive
    mov di, STAGE2_LOAD_SEG     ; DI = Current segment to read into
    mov si, STAGE2_LBA_START    ; SI = LBA that stage2 starts at
    jmp .chk_for_last_lba       ; Check to see if we are last sector in stage2

.read_sector_loop:
    mov bp, DISK_RETRIES        ; Set disk retry count

    call lba_to_chs             ; Convert current LBA to CHS
    mov es, di                  ; Set ES to current segment number to read into
    xor bx, bx                  ; Offset zero in segment

.retry:
    mov ax, 0x0201              ; Call function 0x02 of int 13h (read sectors)
                                ;     AL = 1 = Sectors to read
    int 0x13                    ; BIOS Disk interrupt call
    jc .disk_error              ; If CF set then disk error

.success:
    add di, 512>>4              ; Advance to next 512 byte segment (0x20*16=512)
    inc si                      ; Next LBA

.chk_for_last_lba:
    cmp si, STAGE2_LBA_END      ; Have we reached the last stage2 sector?
    jl .read_sector_loop        ;     If we haven't then read next sector

.stage2_loaded:
    mov ax, STAGE2_RUN_SEG      ; Set up the segments appropriate for Stage2 to run
    mov ds, ax
    mov es, ax

    ; FAR JMP to the Stage2 entry point at physical address 0x07e00
    jmp STAGE2_RUN_SEG:STAGE2_RUN_OFS

.disk_error:
    xor ah, ah                  ; Int13h/AH=0 is drive reset
    int 0x13
    dec bp                      ; Decrease retry count
    jge .retry                  ; If retry count not exceeded then try again

error_end:
    ; Unrecoverable error; print drive error; enter infinite loop
    mov si, diskErrorMsg        ; Display disk error message
    call print_string
    cli
.error_loop:
    hlt
    jmp .error_loop

; Function: print_string
;           Display a string to the console on display page 0
;
; Inputs:   SI = Offset of address to print
; Clobbers: AX, BX, SI

print_string:
    mov ah, 0x0e                ; BIOS tty Print
    xor bx, bx                  ; Set display page to 0 (BL)
    jmp .getch
.repeat:
    int 0x10                    ; print character
.getch:
    lodsb                       ; Get character from string
    test al,al                  ; Have we reached end of string?
    jnz .repeat                 ;     if not process next character
.end:
    ret

;    Function: lba_to_chs
; Description: Translate Logical block address to CHS (Cylinder, Head, Sector).
;              Works for all valid FAT12 compatible disk geometries.
;
;   Resources: http://www.ctyme.com/intr/rb-0607.htm
;              https://en.wikipedia.org/wiki/Logical_block_addressing#CHS_conversion
;              https://stackoverflow.com/q/45434899/3857942
;              Sector    = (LBA mod SPT) + 1
;              Head      = (LBA / SPT) mod HEADS
;              Cylinder  = (LBA / SPT) / HEADS
;
;      Inputs: SI = LBA
;     Outputs: DL = Boot Drive Number
;              DH = Head
;              CH = Cylinder (lower 8 bits of 10-bit cylinder)
;              CL = Sector/Cylinder
;                  Upper 2 bits of 10-bit Cylinders in upper 2 bits of CL
;                   Sector in lower 6 bits of CL
;
;       Notes: Output registers match expectation of Int 13h/AH=2 inputs
;
lba_to_chs:
    push ax                     ; Preserve AX
    mov ax, si                  ; Copy LBA to AX
    xor dx, dx                  ; Upper 16-bit of 32-bit value set to 0 for DIV
    div word [sectorsPerTrack]  ; 32-bit by 16-bit DIV : LBA / SPT
    mov cl, dl                  ; CL = S = LBA mod SPT
    inc cl                      ; CL = S = (LBA mod SPT) + 1
    xor dx, dx                  ; Upper 16-bit of 32-bit value set to 0 for DIV
    div word [numHeads]         ; 32-bit by 16-bit DIV : (LBA / SPT) / HEADS
    mov dh, dl                  ; DH = H = (LBA / SPT) mod HEADS
    mov dl, [bootDevice]        ; boot device, not necessary to set but convenient
    mov ch, al                  ; CH = C(lower 8 bits) = (LBA / SPT) / HEADS
    shl ah, 6                   ; Store upper 2 bits of 10-bit Cylinder into
    or  cl, ah                  ;     upper 2 bits of Sector (CL)
    pop ax                      ; Restore scratch registers
    ret

; Uncomment these lines if not using a BPB (via bpb.inc)
; numHeads:        dw 2         ; 1.44MB Floppy has 2 heads & 18 sector per track
; sectorsPerTrack: dw 18

bootDevice:      db 0x00
diskErrorMsg:    db "Unrecoverable disk error!", 0

; Pad boot sector to 510 bytes and add 2 byte boot signature for 512 total bytes
TIMES 510-($-$$) db  0
dw 0xaa55

; Beginning of stage2. This is at 0x7E00 and will allow your stage2 to be 32.5KiB
; before running into problems. DL will be set to the drive number originally
; passed to us by the BIOS.

NUM_STAGE2_SECTORS equ (stage2_end-stage2_start+511) / 512
                                ; Number of 512 byte sectors stage2 uses.

stage2_start:
    ; Insert stage2 binary here. It is done this way since we
    ; can determine the size(and number of sectors) to load since
    ;     Size = stage2_end-stage2_start
    incbin "stage2.bin"

; End of stage2. Make sure this label is LAST in this file!
stage2_end: 
