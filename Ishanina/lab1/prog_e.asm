STACKK	SEGMENT	STACK
			
	DW 100h DUP(?)

STACKK    	ENDS

DATA		SEGMENT

STRING			db	'Type your PC: $'
STRING_ONE		db	'PC$'
STRING_TWO		db	'PC/XT$'
STRING_TREE		db	'AT$'
STRING_FOUR		db	'PS2 model 30$'
STRING_FIVE		db	'PS2 model 80$'
STRING_SIX		db	'PCjr$'
STRING_SEVEN	db	'PC Convertible$'
VERS			db	0DH, 0AH, 'OS version: 0 .0   $'
OEM 			db	0DH, 0AH, 'OEM:     ', '$'
NUMBER 			db	0DH, 0AH, 'Serial number:        ', '$'
ERRO			db	'ERROR ERROR ERROR!', 0DH, 0AH, '$'

DATA		ENDS

CODE		SEGMENT
ASSUME 	CS:CODE, DS:DATA, SS:STACKK

;процедура получения символа в 16 с/c
TETR_TO_HEX	PROC	near
 
		and	AL,0Fh
		cmp	AL,09
		jbe	NEXT
		add	AL,07
		
NEXT:	add	AL,30h
		ret 

TETR_TO_HEX	ENDP

;процедура перевода байта в AL в два символа 16 с/c в AX
BYTE_TO_HEX	PROC	near

		push CX
		mov	AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov	CL,4
		shr	AL,CL
		call TETR_TO_HEX 	;в AL старшая цифра
		pop	CX				;в AH младшая цифра
		ret 
		
BYTE_TO_HEX	ENDP

;процедура записи 16-ти разраядного числа в 16 с/c в строку
WRD_TO_HEX	PROC	near

		push	BX
		mov	BH,AH
		call	BYTE_TO_HEX
		mov	[DI],AH
		dec	DI
		mov	[DI],AL
		dec	DI
		mov	AL,BH
		call	BYTE_TO_HEX
		mov	[DI],AH
		dec	DI
		mov	[DI],AL
		pop	BX
		ret 
WRD_TO_HEX ENDP

;процедура записи числа в 10 с/c в строку
BYTE_TO_DEC	PROC	near

		push	CX
		push	DX
		xor	AH,AH
		xor	DX,DX
		mov	CX,10 
		
loop_bd:div	CX
		or	DL,30h
		mov	[SI],DL
		dec	SI
		xor	DX,DX
		cmp	AX,10
		jae	loop_bd
		cmp	AL,00h
		je	end_l
		or	AL,30h
		mov	[SI],AL
		
end_l:	pop	DX
		pop	CX
		ret
		
BYTE_TO_DEC	ENDP

BEGIN 	PROC	FAR
          	
		;сохранение адреса возврата в DOS
		PUSH DS		
       	SUB  AX, AX
        PUSH AX
       	MOV  AX, DATA
       	MOV  DS, AX

		;получение типа устройства 
       	MOV	AX, 0F000H
		MOV	ES, AX
		MOV	AL, ES:[0FFFEH]
		
		mov	DX, OFFSET STRING		; Вывод строки текста из поля STRING
	
		push	AX
       	mov	AH, 09h
        int	21h
		pop	AX 

		;поиск нужной строки  
		cmp 	AL, 0FFH
		mov	DX, OFFSET STRING_ONE
		jmp 	RESULT
		cmp 	AL, 0FEH
		mov 	DX, OFFSET STRING_TWO
		jmp 	RESULT
		cmp 	AL, 0FBH
		mov 	DX, OFFSET STRING_TWO
		jmp 	RESULT
		cmp	AL, 0FCH
		mov 	DX, OFFSET STRING_TREE
		jmp 	RESULT
		cmp 	AL, 0FAH
		mov 	DX, OFFSET STRING_FOUR
		jmp 	RESULT
		cmp 	AL, 0F8H
		mov 	DX, OFFSET STRING_FIVE
		jmp 	RESULT
		cmp 	AL, 0FDH
		mov 	DX, OFFSET STRING_SIX
		jmp 	RESULT
		cmp 	AL, 0F9H
		mov 	DX, OFFSET STRING_SEVEN
		jmp 	RESULT	

		;если код ни с чем не совпал,
		;то выводим его на экран
		;с соответствующем сообщением

		mov	DI, OFFSET ERRO
		add	DI, 24h
		call	BYTE_TO_HEX
		mov	[DI], AX
		mov	DX, OFFSET ERRO

RESULT:
		push	AX
       	mov	AH, 09h
        int	21h
		pop	AX 

		;получение версии
		MOV	 AH, 30H
		INT	 21H
		PUSH AX
	
		;определение версии системы и её печать
       	MOV	 SI, OFFSET VERS
		ADD	 SI, 0FH
		CALL BYTE_TO_DEC

		ADD	 SI, 4H 
		POP	 AX
		MOV	 AL, AH
		CALL BYTE_TO_DEC
		MOV	 DX, OFFSET VERS
		push AX
       	mov	AH, 09h
        int	21h
		pop	AX 
	
		;вывод серийного номера OEM
		MOV  SI, OFFSET OEM
		ADD  SI, 8H
		MOV	 AL, BH
		CALL BYTE_TO_DEC
		MOV	 DX, OFFSET OEM
		push AX
       	mov	AH, 09h
        int	21h
		pop	AX 
	
		;вывод номера пользователя
		MOV	 DI, OFFSET NUMBER
		ADD	 DI, 16H
		MOV	 AX, CX
		CALL WRD_TO_HEX
		MOV	 AL, BL
		CALL BYTE_TO_HEX
		SUB	 DI, 2H
		MOV	 [DI], AX
		MOV	 DX, OFFSET NUMBER
		push	AX
       	mov	AH, 09h
        int	21h
		pop	AX 

       	RET
       
BEGIN		ENDP
CODE		ENDS
END 		BEGIN