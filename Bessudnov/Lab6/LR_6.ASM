CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, SS:ASTACK
	
ASTACK SEGMENT STACK
	DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
	FILE_NAME  	db 	"LR_2_M.COM", 0
	PATH 		db 128 dup(0)
	MES_ERR_7 	db "ERROR 7: destriyed MCB",10,13,"$"
	MES_ERR_8 	db "ERROR 8: low memory",10,13,"$"
	MES_ERR_9 	db "ERROR 9: wrong address",10,13,"$"
	MES_GOOD  	db "Free memory",10,13,"$"
	
	MES_END_SUC		db  10, 13,"Program ended",10, 13, "$"
	MES_END_CTRLC	db "Program ended with CRTL+C command", 10, 13, "$"
	MES_END_DEV     db "Program ended with device error",10,13,"$"
	MES_END_RES     db "Program ended with 31h",10,13,"$"
	
	MES_LOAD_ERR1  db "LOAD_MODULE ERROR 1: wrong number",10,13,"$"
	MES_LOAD_ERR2  db "LOAD_MODULE ERROR 2: file not found",10,13,"$"
	MES_LOAD_ERR5  db "LOAD_MODULE ERROR 5: disk error",10,13,"$"
	MES_LOAD_ERR8  db "LOAD_MODULE ERROR 8: low memory",10,13,"$"
	MES_LOAD_ERR10 db "LOAD_MODULE ERROR 10: wrong environment string",10,13,"$"
	MES_LOAD_ERR11 db "LOAD_MODULE ERROR 11: wrong format",10,13,"$"
	
	COM_LINE 	db 1h, 0Dh 	
	PAR_BLOCK 	dw 0
				dd 0 
				dd 0 
				dd 0 
	
	KEEP_SS  dw 0
	KEEP_SP  dw 0
	KEEP_PSP dw 0

	DATA_END db 0
DATA ENDS

	
WRITE_STR PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
WRITE_STR ENDP
	
FREE_MEMORY PROC NEAR
		push BX
		push DX
		mov BX, offset PROGRAMM_END
		mov AX, offset DATA_END
		add BX, AX
		push CX
		mov CL, 4
		shr BX, CL
		add BX, 2Bh
		pop CX
		mov AH, 4Ah
		int 21h
		
		jnc MEM_GOOD

		cmp AX, 7
		je ERR_7
		cmp AX, 8
		je ERR_8
		cmp AX, 9
		je ERR_9

ERR_7:
		mov DX, offset MES_ERR_7
		jmp FAIL
ERR_8:
		mov DX, offset MES_ERR_8
		jmp FAIL
ERR_9:
		mov DX, offset MES_ERR_9
		jmp FAIL
MEM_GOOD:
		mov AX, 1
		mov DX, offset MES_GOOD
		call WRITE_STR
		jmp FREE_MEMORY_END

FAIL:
		mov AX, 0
		call WRITE_STR
		
FREE_MEMORY_END:
		pop DX
		pop BX
		ret
FREE_MEMORY ENDP
	
	
LOAD_MODULE PROC NEAR
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES
		
		mov KEEP_SP, SP
		mov KEEP_SS, SS

		mov AX, DATA
		mov ES, AX
		mov BX, offset PAR_BLOCK
		mov DX, offset COM_LINE
		mov [BX+2], DX
		mov [BX+4], DS
		mov DX, offset PATH

		mov AX, 4B00h
		int 21h

		mov SS, KEEP_SS 
		mov SP, KEEP_SP 
		pop ES
		pop DS

		jnc LOAD_GOOD

		cmp AX, 1
		je LOAD_ERR_1
		cmp AX, 2
		je LOAD_ERR_2
		cmp AX, 5
		je LOAD_ERR_5
		cmp AX, 8
		je LOAD_ERR_8
		cmp AX, 10
		je LOAD_ERR_10
		cmp AX, 11
		je LOAD_ERR_11

LOAD_ERR_1:
		mov DX, offset MES_LOAD_ERR1
		jmp LOAD_FAIL
LOAD_ERR_2:
		mov DX, offset MES_LOAD_ERR2
		jmp LOAD_FAIL
LOAD_ERR_5:
		mov DX, offset MES_LOAD_ERR5
		jmp LOAD_FAIL
LOAD_ERR_8:
		mov DX, offset MES_LOAD_ERR8
		jmp LOAD_FAIL
LOAD_ERR_10:
		mov DX, offset MES_LOAD_ERR10
		jmp LOAD_FAIL
LOAD_ERR_11:
		mov DX, offset MES_LOAD_ERR11
		jmp LOAD_FAIL
LOAD_GOOD:
		mov AH, 4Dh
		mov AL, 00h
		int 21h
		cmp AH, 0
		je GOOD
		cmp AH, 1
		je CTRLC
		cmp AH, 2
		je DEV
		cmp AH, 3
		je RES

GOOD:
		mov DX, offset MES_END_SUC
		jmp LOAD_GOOD_END
CTRLC:
		mov DX, offset MES_END_CTRLC
		jmp LOAD_GOOD_END
DEV:
		mov DX, offset MES_END_DEV
		jmp LOAD_GOOD_END
RES:
		mov DX, offset MES_END_RES
		jmp LOAD_GOOD_END

LOAD_GOOD_END:				
		call WRITE_STR
		jmp LOAD_END

LOAD_FAIL:
		call WRITE_STR
LOAD_END:
		pop DX
		pop CX
		pop BX
		pop AX
		ret
LOAD_MODULE ENDP
	
MAIN PROC
		PUSH DS
		SUB AX, AX
		PUSH AX
		MOV AX, DATA
		MOV DS, AX
		mov KEEP_PSP, ES
		
		call FREE_MEMORY	
		
		cmp AX, 2
		je MAIN_END
		
		;----------------------------------
		mov AX, KEEP_PSP
		mov ES, AX
		mov ES, ES:[2Ch]
		mov BX, 0
		
PRINT_ENV_VAR:
		cmp BYTE PTR ES:[BX], 0
		je ENV_VAR_END
		inc BX
		jmp PRINT_ENV_VAR
ENV_VAR_END:
		inc BX
		cmp BYTE PTR ES:[BX+1], 0
		jne PRINT_ENV_VAR
			
		add BX, 2 	
		mov DI, 0
MARK:
		mov DL, ES:[BX]
		mov BYTE PTR [PATH+DI], DL
		inc BX
		inc DI
		cmp DL, 0
		je LOOP_END
		cmp DL, '\'
		jne MARK
		mov CX, DI
		jmp MARK
LOOP_END:
		mov DI, CX
		mov SI, 0
FILE_NAME_LOOP:
		mov DL, BYTE PTR [FILE_NAME+SI]
		mov BYTE PTR [PATH+DI], DL
		inc DI
		inc SI
		cmp DL, 0
		jne FILE_NAME_LOOP
		;----------------------------------
		
		call LOAD_MODULE
		
MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
MAIN ENDP
		PROGRAMM_END:

CODE ENDS

END MAIN 