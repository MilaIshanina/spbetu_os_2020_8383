DATA SEGMENT

	KEEP_SS  dw 0
	KEEP_SP  dw 0
	KEEP_PSP dw 0
	
	PARAMETERS_BLOCK dw 0 ; seg address of env
					 dd 0 ; seg and offset of cmd
					 dd 0
					 dd 0
	
	MEM_ERROR_7 db "The control block destroyed",0dh,0ah,'$'
	MEM_ERROR_8 db "Not enough memory to perform the function",0dh,0ah,'$'
	MEM_ERROR_9 db "Invalid address of the memory block",0dh,0ah,'$'
	MEM_SUCCESS db "Successful free",0dh,0ah,'$'

	LOAD_ERROR_1 db "Invalid function number",0dh,0ah,'$'
	LOAD_ERROR_2 db "File not found",0dh,0ah,'$'
	LOAD_ERROR_5 db "Disk error",0dh,0ah,'$'
	LOAD_ERROR_8 db "Insufficient memory",0dh,0ah,'$'
	LOAD_ERROR_10 db "Invalid environment string",0dh,0ah,'$'
	LOAD_ERROR_11 db "Incorrect format",0dh,0ah,'$'
	LOAD_SUCCESS db 0dh,0ah,"Successful load",0dh,0ah,'$'

	END_CODE_0 db "Successful end with code  ",0dh,0ah,'$'
	END_CODE_1 db "Reason - Ctrl-Break",0dh,0ah,'$'
	END_CODE_2 db "Reason - Device error",0dh,0ah,'$'
	END_CODE_3 db "Reason - 31h",0dh,0ah,'$'

	PROGRAM_NAME db "PROG2.COM",0
	FULL_PATH db 128 dup(0)
	COMMAND_LINE db 1h, 0Dh 
	DATA_END db 0

DATA ENDS

AStack SEGMENT STACK
	DW 200 DUP(?)
AStack ENDS

CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

	Write_message	PROC
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	Write_message	ENDP

	FREE_EXTRA_MEMORY PROC NEAR
		push BX
		push DX
		push CX

		mov BX, offset PROGRAM_END
		mov AX, offset DATA_END
		add BX, AX

		mov CL, 4
		shr BX, CL
		add BX, 100h

		mov AH, 4Ah
		int 21h

		jnc FREE_MEMORY_SUCCESS

		cmp AX, 7
		je MEMORY_ERROR7
		cmp AX, 8
		je MEMORY_ERROR8
		cmp AX, 9
		je MEMORY_ERROR9

		MEMORY_ERROR7:
			lea DX, MEM_ERROR_7 
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END
		MEMORY_ERROR8:
			lea DX, MEM_ERROR_8
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END
		MEMORY_ERROR9:
			lea DX, MEM_ERROR_9 
			call Write_message
			mov AX,0
			jmp FREE_MEMORY_END

		FREE_MEMORY_SUCCESS:
			lea DX, MEM_SUCCESS
			call Write_message
			mov AX,1		

		FREE_MEMORY_END:
		pop CX
		pop DX
		pop BX

		ret
	FREE_EXTRA_MEMORY ENDP

	CREATE_PATH PROC NEAR
		push AX
		push CX
		push BX
		push DI
		push SI
		push ES

		mov AX, KEEP_PSP
		mov ES, AX
		mov ES, ES:[2Ch]

		mov BX, 0
		print_env_variable:
			cmp BYTE PTR ES:[BX], 0
			je variable_end
			inc BX
			jmp print_env_variable
		variable_end:
			inc BX
			cmp BYTE PTR ES:[BX+1], 0
			jne print_env_variable

		add BX, 2

		mov DI, 0
		path_loop:
			mov DL, ES:[BX]
			mov BYTE PTR [FULL_PATH+DI], DL
			inc BX
			inc DI
			cmp DL, 0
			je path_loop_end
			cmp DL, '\'
			jne path_loop 
			mov CX, DI
			jmp path_loop
		path_loop_end:
		mov DI, CX

		mov SI, 0
		filename_loop:
			mov DL, BYTE PTR [PROGRAM_NAME +SI]
			mov BYTE PTR [FULL_PATH+DI], DL
			inc DI
			inc SI
			cmp DL, 0
			jne filename_loop

		pop ES
		pop SI
		pop DI
		pop BX
		pop CX
		pop AX

		ret
	CREATE_PATH ENDP

	LOAD PROC NEAR
		push AX
		push BX
		push DX

		push DS
		push ES
		mov KEEP_SP, SP
		mov KEEP_SS, SS

		mov AX, DATA
		mov ES, AX
		lea BX, PARAMETERS_BLOCK
		lea DX, COMMAND_LINE
		mov [BX+2], DX 		
		mov [BX+4], DS 	
		lea DX, FULL_PATH

		mov AX, 4B00h
		int 21h

		mov SS, KEEP_SS 
		mov SP, KEEP_SP 
		pop ES
		pop DS

		jnc LOAD_SUCCESS_POINT
	
		cmp AX, 1
		je LOAD_ERROR_CODE_1
		cmp AX, 2
		je LOAD_ERROR_CODE_2
		cmp AX, 5
		je LOAD_ERROR_CODE_5
		cmp AX, 8
		je LOAD_ERROR_CODE_8
		cmp AX, 10
		je LOAD_ERROR_CODE_10
		cmp AX, 11
		je LOAD_ERROR_CODE_11
		

		LOAD_ERROR_CODE_1:
			lea DX, LOAD_ERROR_1 
			call Write_message
			jmp END_LOAD
		LOAD_ERROR_CODE_2:
			lea DX, LOAD_ERROR_2
			call Write_message
			jmp END_LOAD
		LOAD_ERROR_CODE_5:
			lea DX, LOAD_ERROR_5 
			call Write_message
			jmp END_LOAD
		LOAD_ERROR_CODE_8:
			lea DX, LOAD_ERROR_8 
			call Write_message
			jmp END_LOAD
		LOAD_ERROR_CODE_10:
			lea DX, LOAD_ERROR_10 
			call Write_message
			jmp END_LOAD
		LOAD_ERROR_CODE_11:
			lea DX, LOAD_ERROR_11
			call Write_message
			jmp END_LOAD

		LOAD_SUCCESS_POINT:
			lea DX, LOAD_SUCCESS
			call Write_message
		
		mov AH, 4Dh
		mov AL, 00h
		int 21h	

		cmp AH, 0
		je REASON_CODE_0
		cmp AH, 1
		je REASON_CODE_1
		cmp AH, 2
		je REASON_CODE_2
		cmp AH, 3
		je REASON_CODE_3

		REASON_CODE_0:
			lea DX, END_CODE_0
			mov BX,DX
			mov [BX+25],AL
			call Write_message
			jmp END_LOAD
		REASON_CODE_1:
			lea DX, END_CODE_1
			call Write_message
			jmp END_LOAD
		REASON_CODE_2:
			lea DX, END_CODE_2 
			call Write_message
			jmp END_LOAD
		REASON_CODE_3:
			lea DX, END_CODE_3 
			call Write_message
		
		END_LOAD:
		pop DX
		pop BX
		pop AX

		ret
	LOAD ENDP

	MAIN PROC
		PUSH DS
		SUB AX, AX
		PUSH AX
		MOV AX, DATA
		MOV DS, AX
		mov KEEP_PSP, ES

		call FREE_EXTRA_MEMORY
		cmp AX,0
		je MAIN_END

		call CREATE_PATH

		call LOAD

		MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	MAIN ENDP
	PROGRAM_END:

CODE ENDS

END MAIN