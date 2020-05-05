LR3 SEGMENT
ASSUME CS:LR3, DS:LR3, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
ENTER db 13, 10, '$'
AVIABLE db "Aviable memory: $"
BYTES db " bytes", 13, 10, '$'
EXTENDED db "Extended memory: $"
KBYTES db " kbytes", 13, 10, '$'
MCB db "MCB: $"
FREE db "Free$"
OS_XMS db "OS XMS UMB$"
TOP db "Top memory$"
DOS db "MS DOS$"
BLOCK db "Control block 386MAX UMB$"
BLOCKED db "Blocked 386MAX$"
S_386MAX db "386MAX UMB$"
S_SIZE db 13, 10, "Size: $"
FREE_SUCCES db "Memory was free", 13, 10, '$'
FREE_ERROR db "Memory wasn't free", 13, 10, '$'
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP

WRITE_DEC PROC near
    push AX
    push BX
    push CX
    push DX
    xor CX,CX
    mov BX,10
loop_bd: 
    div BX
    push DX
    xor DX,DX
    inc CX
    cmp AX,0h
    jnz loop_bd
writing_num:
    pop DX
    or DL,30h
    call WRITE_SYMBOL
    loop writing_num
    pop DX
    pop CX
    pop BX
    pop AX
    ret
WRITE_DEC ENDP

WRITE_SYMBOL PROC near
    push AX
    mov AH, 02H
    int 21H
    pop AX
    ret
WRITE_SYMBOL ENDP

WRITE_STRING PROC near
    push AX
    mov AH, 09H
    int 21H
    pop AX
    ret
WRITE_STRING ENDP

WRITE_HEX PROC near
    push AX
    mov AL, AH
    call BYTE_TO_HEX
    mov DL, AH
    call WRITE_SYMBOL
    mov DL, AL
    call WRITE_SYMBOL
    pop AX
    call BYTE_TO_HEX
    mov DL, AH
    call WRITE_SYMBOL
    mov DL, AL
    call WRITE_SYMBOL
    ret
WRITE_HEX ENDP

WRITE_AVIABLE_MEMORY PROC near
    push AX
    push BX
    push DX
    mov DX, offset AVIABLE
    call WRITE_STRING
    mov AH,4AH
    mov BX,0FFFFH
    int 21H
    mov AX,BX
    mov BX,10H
    mul BX
    call WRITE_DEC
    mov DX, offset BYTES
    call WRITE_STRING
    pop DX
    pop BX
    pop AX
    ret
WRITE_AVIABLE_MEMORY ENDP

WRITE_EXTENDED_MEMORY PROC near
    push AX
    push BX
    push DX
    mov DX, offset EXTENDED
    call WRITE_STRING
    mov AL,30H
    out 70H,AL
    in AL,71H
    mov BL,AL
    mov AL,31H
    out 70H,AL
    in AL,71H
    mov BH,AL
    mov AX,BX
    xor DX,DX
    call WRITE_DEC
    mov DX, offset KBYTES
    call WRITE_STRING
    pop DX
    pop BX
    pop AX
    ret
WRITE_EXTENDED_MEMORY ENDP

WRITE_MCB PROC near
    push AX
    push CX
    push DX
    push ES
    push SI
    xor CX,CX
    mov AH,52H
    int 21H
    mov AX,ES:[BX-2]
    mov ES,AX
    mov DX, offset MCB
    call WRITE_STRING
GET_MCB:
    inc CX
    push CX
    xor DX,DX
    mov AX,CX
    ;call WRITE_DEC
    mov DX, offset ENTER
    call WRITE_STRING
    xor AX,AX
    mov AL,ES:[0H]
    push AX
    mov AX,ES:[1H]
    cmp AX,0H
    je WRITING_FREE
    cmp AX,6H
    je WRITING_OS_XMS
    cmp AX,7H
    je WRITING_TOP
    cmp AX,8H
    je WRITING_DOS
    cmp AX,0FFFAH
    je WRITING_BLOCK
    cmp AX,0FFFDH
    je WRITING_BLOCKED
    cmp AX,0FFFEH
    je WRITING_386MAX
    xor DX,DX
    call WRITE_HEX
    jmp GET_SIZE
WRITING_FREE:
    mov DX, offset FREE
    jmp WRITING
WRITING_OS_XMS:
    mov DX, offset OS_XMS
    jmp WRITING
WRITING_TOP:
    mov DX, offset TOP
    jmp WRITING
WRITING_DOS:
    mov DX, offset DOS
    jmp WRITING
WRITING_BLOCK:
    mov DX, offset DOS
    jmp WRITING
WRITING_BLOCKED:
    mov DX, offset DOS
    jmp WRITING
WRITING_386MAX:
    mov DX, offset S_386MAX
WRITING:
    call WRITE_STRING
GET_SIZE:
    mov DX, offset S_SIZE
    call WRITE_STRING
    mov AX,ES:[3H]
    mov BX,10H
    mul BX
    call WRITE_DEC
    mov DX, offset BYTES
    call WRITE_STRING
    xor SI,SI
    mov CX,8
GET_LAST:
    mov DL,ES:[SI+8H]
    call WRITE_SYMBOL
    inc SI
    loop GET_LAST
    mov AX,ES:[3H]
    mov BX,ES
    add BX,AX
    inc BX
    mov ES,BX
    pop AX
    pop CX
    cmp AL,5AH
    je END_WRITING
    ;mov DX,offset ENTER
    ;call WRITE_STRING
    jmp GET_MCB
END_WRITING:
    pop SI
    pop ES
    pop DX
    pop CX
    pop AX
    ret
WRITE_MCB ENDP

FREE_MEMORY PROC near
    push AX
	push BX
	push DX	
	mov BX, offset LR3_END
	add BX, 10FH
	shr BX, 1
    shr BX, 1
    shr BX, 1
    shr BX, 1
	mov AH, 4AH
    int 21H
	jnc SUCCES
	mov DX, offset FREE_ERROR
	call WRITE_STRING
	jmp END_FREE
		
SUCCES:
	mov DX, offset FREE_SUCCES
	call WRITE_STRING
END_FREE:
	pop DX
	pop BX
	pop AX
    ret
FREE_MEMORY ENDP

BEGIN:
    call WRITE_AVIABLE_MEMORY
    call FREE_MEMORY
    call WRITE_EXTENDED_MEMORY
    call WRITE_MCB
    xor AL,AL
    mov AH,4CH
    int 21H
    DW 128 dup(0)
LR3_END:
LR3 ENDS
END START