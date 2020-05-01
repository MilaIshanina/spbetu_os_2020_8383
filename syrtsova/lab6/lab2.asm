TESTPC	   SEGMENT
	   ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	   ORG	   100H
START:	   JMP	   BEGIN

;ДАННЫЕ
    ADDRES_OF_UNAVALIABLE_MEM 	db 'Segment address of unavailable memory:     ', 13, 10 ,'$'
    ADDRES_OF_ENVIRONMENT 		db 'Segment address of environment:     ', 13, 10, '$'
    TAIL 						db 'Tail of comand line                 ', 13, 10, 10, '$'
    NEW_LINE 					db 'Empty line', 13, 10, 10, '$'
    CONTENT_LINE					db 'Content of the environment:', 10, 13, '$'
    EMPTY 						db ' ', 13, 10, '$'
    PATH_LINE					db 'Path:', 10, 13, '$'
    ENDL						db ' ',13, 10, '$' 

;ПРОЦЕДУРЫ

TETR_TO_HEX PROC NEAR
		and 	AL,0Fh
		cmp 	AL,09
		jbe 	NEXT
		add 	AL,07
NEXT: 	add 	AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR		;байт в AL переводится в два символа шестн. числа в AX
		push 	CX
		mov 	AH,AL
		call 	TETR_TO_HEX
		xchg 	AL,AH
		mov 	CL,4
		shr 	AL,CL
		call 	TETR_TO_HEX 	;в AL старшая цифра
		pop 	CX 				;в AH младшая
		ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR ;перевод в 16 с/с 16-ти разрядного числа, в AX - число, DI - адрес последнего символа
		push	BX
		mov		BH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		dec		DI
		mov		AL,BH
		xor		AH,AH
		call	BYTE_TO_HEX
		mov		[DI],AH
		dec		DI
		mov		[DI],AL
		pop		BX
		ret
WRD_TO_HEX		ENDP

BYTE_TO_DEC PROC NEAR 	  ; перевод байта в 10с/с, SI - адрес поля младшей цифры
		push	AX        ; AL содержит исходный байт
		push 	CX
		push 	DX
		xor 	AH,AH
		xor 	DX,DX
		mov 	CX,10
loop_bd: div 	CX
		or 		DL,30h
		mov 	[SI],DL
		dec 	SI
		xor 	DX,DX
		cmp 	AX,10
		jae 	loop_bd
		cmp 	AL,00h
		je 		end_l
		or 		AL,30h
		mov 	[SI],AL
end_l:  pop 	DX
		pop 	CX
		pop		AX
		ret
BYTE_TO_DEC ENDP

PRINT PROC NEAR			;печать сообщения на экран
		push 	AX
		mov 	AH, 09h
		int 	21h
		pop 	AX
		ret
PRINT ENDP

ADDRES_OF_MEMORY PROC NEAR
		push	AX
		push	DI
		push	DX
		mov		AX,DS:[02h]
		mov		DI, OFFSET ADDRES_OF_UNAVALIABLE_MEM
		add		DI, 43
		call	WRD_TO_HEX
		mov		DX, OFFSET ADDRES_OF_UNAVALIABLE_MEM
		call	PRINT
		pop		DX
		pop		DI
		pop		AX
		ret
ADDRES_OF_MEMORY ENDP

ENVIROMENT_ADDRES PROC NEAR
		push	AX
		push	DI
		push	DX
		mov		AX, DS:[2Ch]
		mov		DI, OFFSET ADDRES_OF_ENVIRONMENT
		add		DI, 36
		call	WRD_TO_HEX
		mov		DX, OFFSET ADDRES_OF_ENVIRONMENT
		call	PRINT
		pop		DX
		pop		DI
		pop		AX
		ret
ENVIROMENT_ADDRES ENDP

GET_TAIL PROC NEAR
		push	AX
		push	CX
		push	DI
		push	SI
		xor		CX, CX
		mov		CL, DS:[080h]
		mov		SI, OFFSET TAIL
		add 	SI,	21
		test 	CL, CL
		jz		empty1
		xor		DI, DI
		xor		AX, AX
	gettail:
		mov		AL, DS:[081h+DI]
		mov		[SI], AL
		inc		DI
		inc		SI
		loop 	gettail
		mov		DX, OFFSET TAIL
		call	PRINT
		jmp 	exit1
	empty1:
		mov		DX, OFFSET NEW_LINE
		call	PRINT
	exit1:
		pop 	SI
		pop		DI
		pop		CX
		pop		AX
		ret
GET_TAIL ENDP

CONTENT PROC NEAR
		push 	AX
		push 	DX
		push 	DS
		push 	ES
		mov 	DX, OFFSET CONTENT_LINE
  		call 	PRINT
		mov 	AH, 02h 
		mov 	ES, DS:[2Ch]
		xor 	SI, SI
	writecont:
		mov 	DL, ES:[SI]
		int 	21h		
		cmp 	DL, 0h		
		je		endofline
		inc 	SI			
		jmp 	writecont
	endofline:
		mov 	DX, OFFSET EMPTY 
		call 	PRINT
		inc 	SI
		mov 	DL, ES:[SI]
		cmp 	DL, 0h		
		jne 	writecont
		mov 	DX, OFFSET EMPTY
		call 	PRINT
		pop 	ES
		pop 	DS
		pop 	DX
		pop 	AX
		ret
CONTENT ENDP

PATH PROC NEAR
		push 	AX
		push 	DX
		push 	DS
		push 	ES
		mov 	DX, OFFSET PATH_LINE
		call 	PRINT
		add 	SI, 3h
		mov 	AH, 02h
		mov 	ES, DS:[2Ch]
	writemsg:
		mov 	DL, ES:[SI]
		cmp 	DL, 0h
		je 		endofpath
		int 	21h
		inc 	SI
		jmp 	writemsg
	endofpath:
		pop 	ES
		pop 	DS
		pop 	DX
		pop 	AX
		ret
PATH ENDP

BEGIN:
	call		ADDRES_OF_MEMORY
	call		ENVIROMENT_ADDRES
	call		GET_TAIL
	call		CONTENT
	call		PATH
	mov			DX, offset ENDL
	call		PRINT
	xor 		AL,AL
	mov			AH,01h
	int 		21h
	mov 		AH,4Ch
	int 		21h
TESTPC ENDS
END START