; Шаблон текста программы на ассемблере для модуля типа .COM
CODE	SEGMENT
		ASSUME	CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING 
		ORG	100H
START:	JMP	BEGIN
; ДАННЫЕ
;STRING	db	'Значение регистра  AX=	',0DH,0AH,'$'
STRING	db	'Type your PC: $'
STRING_ONE		db	'PC$'
STRING_TWO		db	'PC/XT$'
STRING_TREE		db	'AT$'
STRING_FOUR		db	'PS2 model 30$'
STRING_FIVE		db	'PS2 model 80$'
STRING_SIX		db	'PCjr$'
STRING_SEVEN	db	'PC Convertible$'
VERSI			db	0DH, 0AH, 'OS version: 0 .0   $'
OEM 			db	0DH, 0AH, 'OEM:     ', '$'
NUMBER 			db	0DH, 0AH, 'Serial number:        ', '$'
ERRO			db	'ERROR ERROR ERROR!', 0DH, 0AH, '$'
;-----------------------------------------------------
;процедура получения символа в 16 с/с
TETR_TO_HEX	PROC	near
 
		and	AL,0Fh
		cmp	AL,09
		jbe	NEXT
		add	AL,07
		
NEXT:	add	AL,30h
		ret 

TETR_TO_HEX	ENDP

;процедура, в которй байт в AL переводится в два символа шестн. числа в AX
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

;процедура, в которй происходит перевод в 16 c/c  16-ти  разрядного числа
; в AX - число, DI - адрес последнего символа
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

;процедура, где происходит перевод в 10c/c, SI - адрес поля младшей цифры
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

; КОД
 
BEGIN:

mov	AX, 0F000H
	mov	ES, AX
	mov	AL, ES:[0FFFEH]	
	mov	DX, OFFSET STRING		; Вывод строки текста из поля STRING
	
	push	AX
       	mov	AH, 09h
        int	21h
	pop	AX 

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

	mov	AH, 30H
	int	21H
	push 	AX
	
    mov	SI, OFFSET VERSI
	add	SI, 0FH
	call BYTE_TO_DEC
	add	SI, 4h 
	pop	AX
	mov	AL, AH
	call BYTE_TO_DEC
	mov	DX, OFFSET VERSI
	
	push	AX
    mov	AH, 09h
    int	21h
	pop	AX 

	mov SI, OFFSET OEM
	add SI, 8H
	mov	AL, BH
	call BYTE_TO_DEC
	mov	DX, OFFSET OEM
		
	push AX
    mov	AH, 09h
    int	21h
	pop	AX 
       
	mov	DI, OFFSET NUMBER 
	add	DI, 16H
	mov	AX, CX
	call	WRD_TO_HEX
	mov	AL, BL
	call 	BYTE_TO_HEX
	sub	DI, 2H
	mov	[DI], AX
	mov	DX, OFFSET NUMBER 
	
	push	AX
       	mov	AH, 09h
        int	21h
	pop	AX 

	xor	AL, AL		; Выход в DOS
	mov	AH, 4CH
	int	21H



CODE	ENDS
		END	START	;конец модуля, START - точка входа
