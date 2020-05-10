AStack SEGMENT STACK
	dw 128 dup(0)
Astack ENDS

DATA SEGMENT
	PARAMETER_BLOCK dw 0 ;сегментный адрес среды
                  dd 0 ;сегмент и смещение командной строки
                  dd 0 ;сегмент и смещение FCB 
                  dd 0 ;сегмент и смещение FCB 
                  
	KEEP_SS dw 0
	KEEP_SP dw 0
	
	STR_SYMBOL db 13, 10, 'SYMBOL:    $'
	IS_MEMORY_FREED db 0
	STR_FUNCTION_COMPLETED db 13, 10, 'Memory freed$'
	STR_FUNC_NOT_COMPLETED db 13, 10, 'Memory is not freed$'
	ERROR_CODE_7 db 13, 10, 'Memory control block destroyed$'
	ERROR_CODE_8 db 13, 10, 'Not enough memory to execute function$'
	ERROR_CODE_9 db 13, 10, 'Invalid memory block address$'
	
	PROGRAM_NAME db 'OS2.COM$'
	PROGRAM_PATH db 50 dup (0)
	STR_COMMAND_LINE db 1h, 0Dh
	
	STR_PROG_NOT_LOADED db 13, 10, 'Program not loaded$'
	STR_LOADING_ERROR_CODE_1 db 13, 10, 'Function number is incorrect$'
	STR_LOADING_ERROR_CODE_2 db 13, 10, 'File not found$'
	STR_LOADING_ERROR_CODE_5 db 13, 10, 'Disc error$'
	STR_LOADING_ERROR_CODE_8 db 13, 10, 'Insufficient memory$'
	STR_LOADING_ERROR_CODE_10 db 13, 10, 'Wrong environment string$'
	STR_LOADING_ERROR_CODE_11 db 13, 10, 'Invalid format$'
	
	STR_PROGRAM_END db 13, 10, 'The program ended with $'
	STR_END_CODE_0 db 'Normal completion$'
	STR_END_CODE_1 db 'Completion by CTRL-Break$'
	STR_END_CODE_2 db 'Device error termination$'
	STR_END_CODE_3 db 'Termination by function 31h leaving the program resident$'

	END_OF_DATAA db 0 
	
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

;--------------------------------------------------
PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
    ret
PRINT ENDP
;----------------------------------------------
LOADING_MODULE_LR2 PROC near
	push AX
	push BX
	push DX
	
	push DS
	push ES
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	
	mov AX, DATA
	mov ES, AX
	
    mov BX, offset PARAMETER_BLOCK
	mov DX, offset COMMAND_LINE
	mov [BX + 2], DX
	mov [BX + 4], DS
	mov DX, offset PROGRAM_PATH
	
	mov AX, 4B00h
	int 21h
	mov SS, KEEP_SS
	mov SP, KEEP_SP
   
	pop ES
	pop DS
	
	jnc PROGRAM_UPLOADED
	mov DX, offset STR_PROG_NOT_LOADED
	call PRINT
	cmp AX, 1
	je LOADING_ERROR_CODE_1
	cmp AX, 2
	je LOADING_ERROR_CODE_2
	cmp AX, 5
	je LOADING_ERROR_CODE_5
	cmp AX, 8
	je LOADING_ERROR_CODE_8
	cmp AX, 10
	je LOADING_ERROR_CODE_10
	cmp AX, 11
	je LOADING_ERROR_CODE_11
	LOADING_ERROR_CODE_1:
		mov DX, offset STR_LOADING_ERROR_CODE_1
		call PRINT
		jmp END_OF_LOADING_LR2
	LOADING_ERROR_CODE_2:
		mov DX, offset STR_LOADING_ERROR_CODE_2
		call PRINT
		jmp END_OF_LOADING_LR2
	LOADING_ERROR_CODE_5:
		mov DX, offset STR_LOADING_ERROR_CODE_5
		call PRINT
		jmp END_OF_LOADING_LR2
	LOADING_ERROR_CODE_8:
		mov DX, offset STR_LOADING_ERROR_CODE_8
		call PRINT
		jmp END_OF_LOADING_LR2
	LOADING_ERROR_CODE_10:
		mov DX, offset STR_LOADING_ERROR_CODE_10
		call PRINT
		jmp END_OF_LOADING_LR2
	LOADING_ERROR_CODE_11:
		mov DX, offset STR_LOADING_ERROR_CODE_11
		call PRINT
		jmp END_OF_LOADING_LR2
	PROGRAM_UPLOADED:
		mov AX, 4D00h
		int 21h
		push SI
		mov SI, offset STR_SYMBOL
		mov [SI + 10], AL
		pop SI
		mov DX, offset STR_SYMBOL
		call PRINT
		mov DX, offset STR_PROGRAM_END
		call PRINT
		cmp AH, 0
		je END_CODE_0
		cmp AH, 1
		je END_CODE_1
		cmp AH, 2
		je END_CODE_2
		cmp AH, 3
		je END_CODE_3
	END_CODE_0:
		mov DX, offset STR_END_CODE_0
		call PRINT
		jmp END_OF_LOADING_LR2
	END_CODE_1:
		mov DX, offset STR_END_CODE_1
		call PRINT
		jmp END_OF_LOADING_LR2
	END_CODE_2:
		mov DX, offset STR_END_CODE_2
		call PRINT
		jmp END_OF_LOADING_LR2
	END_CODE_3:
		mov DX, offset STR_END_CODE_3
		call PRINT
	
	END_OF_LOADING_LR2:
		pop DX
		pop BX
		pop AX
		ret
LOADING_MODULE_LR2 ENDP
;----------------------------------------------
COMMAND_LINE PROC near
		push AX
		push DI
		push SI
		push ES
		
		mov ES, ES:[2Ch]	;смещение до сегмента окружения (environment)
		xor DI, DI

	NEXT:	;ищем 2 нуля - т.к. строка запуска программы за ними
		mov AL, ES:[DI]
		;inc DI
		cmp AL, 0
		je AFTER_FIRST_0
		inc DI
		jmp NEXT
		
		
	AFTER_FIRST_0:
		inc DI
		mov AL, ES:[DI]
		cmp AL, 0
		jne NEXT
		add DI, 3h	;нашли 2 нуля, пропускаем 3 цифры
		mov SI, 0
		
	WRITE_NUM:
		mov AL, ES:[DI]
		cmp AL, 0
		je DELETE_FILE_NAME
		mov PROGRAM_PATH[SI], AL
		inc DI
		inc SI
		jmp WRITE_NUM
		
	DELETE_FILE_NAME:
		dec si
		cmp PROGRAM_PATH[SI], '\'
		je READY
		jmp DELETE_FILE_NAME
		
	READY:
		mov DI, -1

	ADD_FILE_NAME:
		inc SI
		inc DI
		mov AL, PROGRAM_NAME[DI]
		cmp AL, '$'
		je END_OF_COMMAND_LINE
		mov PROGRAM_PATH[SI], AL
		jmp ADD_FILE_NAME
		
	END_OF_COMMAND_LINE:	
		pop ES
		pop SI
		pop DI
		pop AX
		ret
COMMAND_LINE ENDP
;----------------------------------------------
FREEING_UP_MEMORY PROC near
	push AX
	push BX
	push CX
	push DX

	mov BX, offset END_OF_PROGRAM
	mov AX, offset END_OF_DATAA
	add BX, AX
	add BX, 30Fh
	mov CL, 4
	shr BX, CL
	mov AX, 4A00h	;сжать или расширить блок памяти
	int 21h	
	jnc FUNCTION_COMPLETED

	mov DX, offset STR_FUNC_NOT_COMPLETED
	call PRINT
	mov IS_MEMORY_FREED, 0
	cmp AX, 7
	je IF_ERROR_CODE_7
	cmp AX, 8
	je IF_ERROR_CODE_8
	cmp AX, 9
	je IF_ERROR_CODE_9
	
	IF_ERROR_CODE_7:
		mov DX, offset ERROR_CODE_7
		call PRINT
		jmp END_OF_FREEING
	IF_ERROR_CODE_8:
		mov DX, offset ERROR_CODE_8
		call PRINT
		jmp END_OF_FREEING
	IF_ERROR_CODE_9:
		mov DX, offset ERROR_CODE_9
		call PRINT
		jmp END_OF_FREEING

	FUNCTION_COMPLETED:
		mov DX, offset STR_FUNCTION_COMPLETED
		call PRINT
		mov IS_MEMORY_FREED, 1

	END_OF_FREEING:
		pop DX
		pop CX
		pop BX
		pop AX
		ret
FREEING_UP_MEMORY ENDP
;----------------------------------------------
BEGIN PROC FAR
	xor AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov BX, DS
	
	call FREEING_UP_MEMORY
	cmp IS_MEMORY_FREED, 1
	jne ENDD
	call COMMAND_LINE
	call LOADING_MODULE_LR2

	ENDD:
		xor AL, AL
		mov AH, 4Ch
		int 21h
BEGIN ENDP
END_OF_PROGRAM:
CODE ENDS
	END BEGIN