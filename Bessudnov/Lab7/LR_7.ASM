CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, SS:ASTACK
	
ASTACK SEGMENT STACK
	DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
	FILE_NAME_1  	db 	"OVL_1.EXE", 0
	FILE_NAME_2  	db 	"OVL_2.EXE", 0
	OFFSET_PROG 	dw 0
	PATH 			db 128 dup(0)
	MES_ERR_7 		db "ERROR 7: destriyed MCB",10,13,"$"
	MES_ERR_8 		db "ERROR 8: low memory",10,13,"$"
	MES_ERR_9 		db "ERROR 9: wrong address",10,13,"$"
	MES_GOOD  		db "Free memory",10,13,"$"
	
	MES_ALLOC_GOOD 		db "Allocation good",10,13,"$"
	MES_ALLOC_ERR_2  	db "ALLOCATION ERROR 2: file not found",10,13,"$"
	MES_ALLOC_ERR_3  	db "ALLOCATION ERROR 3: route not found",10,13,"$"
	
	MES_LOAD_GOOD  db "LOAD good",10,13,"$"
	MES_LOAD_ERR1  db "LOAD_MODULE ERROR 1: function not exist",10,13,"$"
	MES_LOAD_ERR2  db "LOAD_MODULE ERROR 2: file not found",10,13,"$"
	MES_LOAD_ERR3  db "LOAD_MODULE ERROR 3: route not found",10,13,"$"
	MES_LOAD_ERR4  db "LOAD_MODULE ERROR 4: too many opened files",10,13,"$"
	MES_LOAD_ERR5  db "LOAD_MODULE ERROR 5: no accsess",10,13,"$"
	MES_LOAD_ERR8  db "LOAD_MODULE ERROR 8: low memory",10,13,"$"
	MES_LOAD_ERR10 db "LOAD_MODULE ERROR 10: wrong environment string",10,13,"$"
	
	DTA_MEM db 43 dup(?)
	OVL_ADDRESS dd 0	
	
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

ALLOCATE_MEMORY PROC
		push BX
		push CX
		push DX

		push DX 

		mov DX, offset DTA_MEM
		mov AH, 1Ah
		int 21h

		pop DX 
		mov CX, 0
		mov AH, 4Eh
		int 21h

		jnc ALLOC_GOOD

		cmp AX, 2
		jmp ALLOC_ERR_2
		cmp AX, 3
		jmp ALLOC_ERR_3

ALLOC_ERR_2:
		mov DX, offset MES_ALLOC_ERR_2
		jmp ALLOC_FAIL
ALLOC_ERR_3:
		mov DX, offset MES_ALLOC_ERR_3
		jmp ALLOC_FAIL

ALLOC_GOOD:
		push DI
		mov DI, offset DTA_MEM
		mov BX, [DI+1Ah] 
		mov AX, [DI+1Ch]
		pop DI
		push CX
		mov CL, 4
		shr BX, Cl
		mov CL, 12
		shl AX, CL
		pop CX
		add BX, AX
		add BX, 1
		mov AH, 48h
		int 21h
		mov WORD PTR OVL_ADDRESS, AX
		mov DX, offset MES_ALLOC_GOOD
		call WRITE_STR
		mov AX, 1
		jmp ALLOC_END

ALLOC_FAIL:
		mov AX, 0
		call WRITE_STR

ALLOC_END:
		pop DX
		pop CX
		pop BX
		
		ret
ALLOCATE_MEMORY ENDP
	
	
LOAD_MODULE PROC NEAR
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES
		

		mov AX, DATA
		mov ES, AX
		mov DX, offset PATH
		mov BX, offset OVL_ADDRESS
		mov AX, 4B03h
		int 21h


		jnc LOAD_GOOD

		cmp AX, 1
		je LOAD_ERR_1
		cmp AX, 2
		je LOAD_ERR_2
		cmp AX, 3
		je LOAD_ERR_3
		cmp AX, 4
		je LOAD_ERR_4
		cmp AX, 5
		je LOAD_ERR_5
		cmp AX, 8
		je LOAD_ERR_8
		cmp AX, 10
		je LOAD_ERR_10

LOAD_ERR_1:
		mov DX, offset MES_LOAD_ERR1
		jmp LOAD_FAIL
LOAD_ERR_2:
		mov DX, offset MES_LOAD_ERR2
		jmp LOAD_FAIL
LOAD_ERR_3:
		mov DX, offset MES_LOAD_ERR3
		jmp LOAD_FAIL
LOAD_ERR_4:
		mov DX, offset MES_LOAD_ERR4
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

LOAD_GOOD:
		mov DX, offset MES_LOAD_GOOD
		call WRITE_STR
		
		mov AX, WORD PTR OVL_ADDRESS
		mov ES, AX
		mov WORD PTR OVL_ADDRESS, 0
		mov WORD PTR OVL_ADDRESS + 2, AX
		
		call OVL_ADDRESS
		mov ES, AX
		mov AH, 49h
		int 21h
		jmp LOAD_END
		
LOAD_FAIL:
		call WRITE_STR
	
LOAD_END:
		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX
		ret
LOAD_MODULE ENDP



OVL_EXEC PROC
		push DX
		;----------------------------

		mov OFFSET_PROG, DX
	
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
		mov SI, OFFSET_PROG
FILE_NAME_LOOP:
		mov DL, BYTE PTR [SI]
		mov BYTE PTR [PATH+DI], DL
		inc DI
		inc SI
		cmp DL, 0
		jne FILE_NAME_LOOP
		;----------------------------

		mov DX, offset PATH
		call ALLOCATE_MEMORY
		cmp AX, 1
		jne OVL_EXEC_END

		call LOAD_MODULE
	
OVL_EXEC_END:
		pop DX
		ret
OVL_EXEC ENDP
	
MAIN PROC
		PUSH DS
		SUB AX, AX
		PUSH AX
		MOV AX, DATA
		MOV DS, AX
		mov KEEP_PSP, ES
		
		call FREE_MEMORY	
		cmp AX, 1
		jne MAIN_END
		
		mov DX, offset FILE_NAME_1
		call OVL_EXEC
		
		mov DX, offset FILE_NAME_2
		call OVL_EXEC
		
MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
MAIN ENDP
		PROGRAMM_END:

CODE ENDS

END MAIN 