TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
NEW_LINE db 13, 10, '$'
LOCK_MEM_MES db 'Locked memory: $'
ENV_MES db 'Environment: $'
TAIL_MES db 'Command line tail: $'
NO_TAIL_MES db 'empty as always $'
ENV_CON_MES db 'Enviroment content: $'
PATH_MES db 'Path: $'

;-----------------------------------------
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP
;-----------------------------------------
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
;-----------------------------------------
PRINT_SYMBOL PROC near
    push AX
    mov AH, 02H
    int 21H
    pop AX
    ret
PRINT_SYMBOL ENDP
;-----------------------------------------
PRINT_MESSAGE PROC near
    push AX
    mov AH, 09H
    int 21H
    pop AX
    ret
PRINT_MESSAGE ENDP
;-----------------------------------------
PRINT_HEX PROC near
    push AX
    mov AL, AH
    call BYTE_TO_HEX
    mov DL, AH
    call PRINT_SYMBOL
    mov DL, AL
    call PRINT_SYMBOL
    pop AX
    call BYTE_TO_HEX
    mov DL, AH
    call PRINT_SYMBOL
    mov DL, AL
    call PRINT_SYMBOL
    ret
PRINT_HEX ENDP
;-----------------------------------------

BEGIN:
;--------LOCK_MEM--------
    mov DX, offset LOCK_MEM_MES
    call PRINT_MESSAGE
    mov AX, DS:[02H]
    call PRINT_HEX
    mov DX, offset NEW_LINE
    call PRINT_MESSAGE
;--------ENV--------
    mov DX, offset ENV_MES
    call PRINT_MESSAGE
    mov AX, DS:[2CH]
    call PRINT_HEX
    mov DX, offset NEW_LINE
    call PRINT_MESSAGE
;--------TAIL--------
    mov DX, offset TAIL_MES
    call PRINT_MESSAGE
    mov CX, 0
    mov CL, DS:[80H]
    cmp CL, 0
    je TAIL_EMPTY
    mov DI, 0
	xor DX, DX
TAIL_LOOP:
	mov DL, DS:[81H + DI]
	call PRINT_SYMBOL
	inc DI
	loop TAIL_LOOP
	jmp TAIL_END
TAIL_EMPTY:
	mov DX, OFFSET NO_TAIL_MES
	call PRINT_MESSAGE
TAIL_END:
    mov DX, offset NEW_LINE
    call PRINT_MESSAGE
;--------ENV_PATH_MES--------
    mov DX, offset ENV_CON_MES
    call PRINT_MESSAGE
    xor SI, SI
	mov BX, 2CH
	mov ES, [BX]
PRINT_CONTENT:
	cmp BYTE PTR ES:[SI], 0H
	je NEXT_CONTENT
	mov AL, ES:[SI]
    mov DL, AL
	call PRINT_SYMBOL
	jmp CHECK
NEXT_CONTENT:
	mov DX, offset NEW_LINE
	call PRINT_MESSAGE
CHECK:
	inc SI
	cmp WORD PTR ES:[SI], 0001H
    je PRINT_PATH
	jmp PRINT_CONTENT
PRINT_PATH:
	mov DX, offset PATH_MES
	call PRINT_MESSAGE
	add SI, 2
PATH_LOOP:
	cmp BYTE PTR ES:[SI], 00H
	je CONTENT_END
	mov AL, ES:[SI]
    mov DL, AL
	call PRINT_SYMBOL
	inc SI
	jmp PATH_LOOP
CONTENT_END:

	xor AL, AL

	mov AH, 01h
	int 21h

    mov AH, 4CH
    int 21H
TESTPC ENDS
END START