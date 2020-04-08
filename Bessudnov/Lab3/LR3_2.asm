TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
NEW_LINE db 13, 10, '$'
MES_AVIABLE db "Aviable memory: $"
MES_BYTES db " bytes", 13, 10, '$'
MES_EXTENDED_MEM db "Extended memory: $"
MES_KBYTES db " kbytes", 13, 10, '$'
MES_MCB db "MCB list: $"
MES_FREE db "Empty area$"
MES_OS_XMS db "OS XMS UMB$"
MES_TOP_MEM db "Top memory$"
MES_DOS db "MS DOS$"
MES_BLOCK db "Control block 386MAX UMB$"
MES_BLOCKED db "Blocked 386MAX$"
MES_386MAX db "386MAX UMB$"
MES_SIZE db 13, 10, "Size: $"
MES_FREE_SUCCES db "Memory free success", 13, 10, '$'
MES_FREE_ERROR db "Memory free unsuccess", 13, 10, '$'

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

BEGIN:
	;----------------AVAILABLE_MEM----------------
	mov DX, offset MES_AVIABLE
    call WRITE_STRING
    mov AH,4AH
    mov BX,0FFFFH
    int 21H
    mov AX,BX
    mov BX,10H
    mul BX
    call WRITE_DEC
    mov DX, offset MES_BYTES
    call WRITE_STRING
	;--------------------------------
	
    mov BX, offset LR3_END
	add BX, 10FH
	shr BX, 1
    shr BX, 1
    shr BX, 1
    shr BX, 1
	mov AH, 4AH
    int 21H
	jnc SUCCESS
	mov DX, offset MES_FREE_ERROR
	call WRITE_STRING
	jmp END_FREE
		
SUCCESS:
	mov DX, offset MES_FREE_SUCCES
	call WRITE_STRING
END_FREE:
	
	;---------------EXTENDED_MEM-----------------
    mov DX, offset MES_EXTENDED_MEM
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
    mov DX, offset MES_KBYTES
    call WRITE_STRING
	;--------------------------------
	
	;---------------MCB-----------------
	xor CX,CX
    mov AH,52H
    int 21H
    mov AX,ES:[BX-2]
    mov ES,AX
    mov DX, offset MES_MCB
    call WRITE_STRING
GET_MCB:
    inc CX
    push CX
    xor DX,DX
    mov AX,CX
    mov DX, offset NEW_LINE
    call WRITE_STRING
    xor AX,AX
    mov AL,ES:[0H]
    push AX
    mov AX,ES:[1H]
    cmp AX,0H
    je PRINTING_FREE
    cmp AX,6H
    je PRINTING_OS_XMS
    cmp AX,7H
    je PRINTING_TOP
    cmp AX,8H
    je PRINTING_DOS
    cmp AX,0FFFAH
    je PRINTING_BLOCK
    cmp AX,0FFFDH
    je PRINTING_BLOCKED
    cmp AX,0FFFEH
    je PRINTING_386MAX
    xor DX,DX
    call WRITE_HEX
    jmp GET_SIZE
PRINTING_FREE:
    mov DX, offset MES_FREE
    jmp PRINTING
PRINTING_OS_XMS:
    mov DX, offset MES_OS_XMS
    jmp PRINTING
PRINTING_TOP:
    mov DX, offset MES_TOP_MEM
    jmp PRINTING
PRINTING_DOS:
    mov DX, offset MES_DOS
    jmp PRINTING
PRINTING_BLOCK:
    mov DX, offset MES_DOS
    jmp PRINTING
PRINTING_BLOCKED:
    mov DX, offset MES_DOS
    jmp PRINTING
PRINTING_386MAX:
    mov DX, offset MES_386MAX
PRINTING:
    call WRITE_STRING
GET_SIZE:
    mov DX, offset MES_SIZE
    call WRITE_STRING
    mov AX,ES:[3H]
    mov BX,10H
    mul BX
    call WRITE_DEC
    mov DX, offset MES_BYTES
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
    je END_PRINTING
    jmp GET_MCB
END_PRINTING:
	;--------------------------------
	
    xor AL,AL
    mov AH,4CH
    int 21H
    DW 128 dup(0)
LR3_END:
TESTPC ENDS
END START 