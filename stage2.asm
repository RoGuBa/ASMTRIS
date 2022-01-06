%include "stage2info.inc"
[bits 16]
[org STAGE2_RUN_OFS] ;interrupt vector table offset

%include "asmtris.asm"

jmp $
