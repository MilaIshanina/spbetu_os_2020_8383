CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack, ES:NOTHING

ROUT PROC FAR
	jmp INTERRUPT_BEGIN
	ADDITION_RESULT dw 0
	CHAR db 0
	INTERRUPT_ID dw 9888h
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_PSP DW 0
	INTERRUPTION_STACK dw 128 dup(0)

	INTERRUPT_BEGIN:
		mov KEEP_SS, SS
  		mov KEEP_SP, SP
   		mov KEEP_AX, AX
		mov AX, SEG INTERRUPTION_STACK
		mov SS, AX
		mov AX, offset INTERRUPTION_STACK
		add AX, 256   ; на конец стека
		mov SP, AX
		push BX
		push CX
		push DX
		push SI
		push DS
		push ES
		mov AX, SEG CHAR
		mov DS, AX

		in AL, 60h	;читать ключ
		cmp AL, 02h
		jne CONTINUE_FROM_1
		mov AX, ADDITION_RESULT	;1
		add AX, 1
		cmp AX, 9
		jg IF_ADD_RES_GREATER_9
		jmp DO_REQ
		CONTINUE_FROM_1:
			cmp AL, 03h
			jne CONTINUE_FROM_2
			mov AX, ADDITION_RESULT	;2
			add AX, 2
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_2:
			cmp AL, 04h
			jne CONTINUE_FROM_3
			mov AX, ADDITION_RESULT	;3
			add AX, 3
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_3:
			cmp AL, 05h
			jne CONTINUE_FROM_4
			mov AX, ADDITION_RESULT	;4
			add AX, 4
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_4:
			cmp AL, 06h
			jne CONTINUE_FROM_5
			mov AX, ADDITION_RESULT	;5
			add AX, 5
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_5:
			cmp AL, 07h
			jne CONTINUE_FROM_6
			mov AX, ADDITION_RESULT	;6
			add AX, 6
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_6:
			cmp AL, 08h
			jne CONTINUE_FROM_7
			mov AX, ADDITION_RESULT	;7
			add AX, 7
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		IF_ADD_RES_GREATER_9:   ;если в результате хранится двузначное число
			add AX, -10
			jmp DO_REQ
		CONTINUE_FROM_7:
			cmp AL, 09h
			jne CONTINUE_FROM_8
			mov AX, ADDITION_RESULT	;8
			add AX, 8
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_8:
			cmp AL, 0Ah
			jne CONTINUE_FROM_9
			mov AX, ADDITION_RESULT
			add AX, 9
			cmp AX, 9
			jg IF_ADD_RES_GREATER_9
			jmp DO_REQ
		CONTINUE_FROM_9:
			cmp AL, 0Bh
			jne IF_NO_CORRECT_SYM
			mov AX, ADDITION_RESULT
			jmp DO_REQ
		IF_NO_CORRECT_SYM:	
			pushf	;уйти на исходный обработчик
			call DWORD PTR CS:KEEP_IP
			jmp END_OF_INT
		DO_REQ: ;следующий код необходим для обработки аппаратного прерывания
			mov ADDITION_RESULT, AX
			add AL, 30h	;перевести число в символ
			mov CHAR, AL
			;int 29h	;вывести его на экран! 
			in AL, 61h	;взять значение порта управления клавиатурой
			mov AH, AL	;сохранить его
			or AL, 80h	;установить бит разрешения для клавиатуры
			out 61h, AL	;и вывести его в управляющий порт
			xchg AL, AL	;извлечь исходное значение порта
			out 61h, AL	;и записать его обратно
			mov AL, 20h	;послать сигнал "конец прерывания"
			out 20h, AL	;контроллеру прерываний 8259

		WRITE_ANS:
			mov AH, 05h	
			mov CL, CHAR
			mov CH, 00h
			int 16h
			or AL, AL
			jz END_OF_INT
			
			mov AX, 0040h
			mov ES, AX
			mov AX, ES:[1Ah]
			mov ES:[1Ch], AX
			jmp WRITE_ANS

		END_OF_INT:
			pop ES
			pop DS
			pop SI
			pop DX
			pop CX
			pop BX
			mov SP, KEEP_SP
			mov AX, KEEP_SS
			mov SS, AX
			mov AX, KEEP_AX
			mov AL, 20h
			OUT 20h, AL
			IRET
ROUT ENDP
LAST_BYTE:
;--------------------------------------------------
PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
    ret
PRINT ENDP
;----------------------------------------------
SET_INTERRUPT PROC near
	push AX
	push BX
	push CX
	push DX
	push DS
	push ES

	mov AH, 35H ; функция получения вектора
	mov AL, 09H ; номер вектора
	int 21H
	mov KEEP_IP, BX ; запоминание смещения
	mov KEEP_CS, ES ; и сегмента

	CLI
	push DS
	mov DX, offset ROUT
	mov AX, seg ROUT
	mov DS, AX
	mov AH, 25H
	mov AL, 09H
	int 21H ; восстанавливаем вектор
	pop DS
	STI

	mov DX, offset LAST_BYTE
	add DX, 10Fh
	mov CL, 4h ; перевод в параграфы
	shr DX, CL
	inc DX ; размер в параграфах
	xor AX, AX
	mov AH, 31h
	int 21h

	pop ES
	pop DS
	pop DX
	pop CX
	pop BX
	pop AX
	ret
SET_INTERRUPT ENDP
;----------------------------------------------
INTERRUPT_UPLOAD PROC near
	push AX
	push BX
	push DX
	push DS
	push ES
	push SI
		
	CLI
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, offset KEEP_IP
	sub SI, offset ROUT
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
	push DS
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS
	mov AX, ES:[BX+SI+4]
	mov ES, AX
	push ES
	mov AX, ES:[2Ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	mov AH, 49h
	int 21h
	STI
		
	pop SI
	pop ES
	pop DS
	pop DX
	pop BX
	pop AX
	ret
INTERRUPT_UPLOAD ENDP
;----------------------------------------------
CHECK_PARAMETER PROC near
	push AX
	push ES
		
	mov AX, KEEP_PSP
	mov ES, AX
	cmp byte ptr ES:[81h+1], '/'
	jne END_OF_PARAMETER
	cmp byte ptr ES:[81h+2], 'u'
	jne END_OF_PARAMETER
	cmp byte ptr ES:[81h+3], 'n'
	jne END_OF_PARAMETER
	mov PARAMETER, 1
		
	END_OF_PARAMETER:
		pop ES
		pop AX
		ret
CHECK_PARAMETER ENDP
;----------------------------------------------
CHECK_09H PROC near
	push AX
	push BX
	push SI

	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, offset INTERRUPT_ID
	sub SI, offset ROUT
	mov AX, ES:[BX+SI]
	cmp AX, 9888h
	jne END_OF_CHECK
	mov IS_INTERRUPT_LOADED, 1

	END_OF_CHECK:
		pop SI
		pop BX
		pop AX
		ret
CHECK_09H ENDP
;----------------------------------------------
BEGIN PROC FAR
	mov AX, DATA
	mov DS, AX
	mov KEEP_PSP, ES	
	
	call CHECK_09H
	call CHECK_PARAMETER
	mov AL, PARAMETER
	cmp AL, 1
	je IF_UN

	mov AL, IS_INTERRUPT_LOADED 
	cmp AL, 1
	jne IF_NEED_TO_SET_INTERRUPT
	mov DX, offset IF_INTERRUPT_SET 
	call PRINT
	jmp ENDD
	
	IF_NEED_TO_SET_INTERRUPT:
		mov DX, offset IF_INTERRUPT_NOTSET
		call PRINT
		call SET_INTERRUPT
		jmp ENDD

	IF_UN:
		mov AL, IS_INTERRUPT_LOADED 
		cmp AL, 1
		jne IF_1CH_NOT_SET
		mov DX, offset STR_UN 
		call PRINT
		call INTERRUPT_UPLOAD
		jmp ENDD

	IF_1CH_NOT_SET:
		mov DX, offset IF_INTERRUPT_NOTSET
		call PRINT

	ENDD:
		xor AL, AL
		mov AH, 4Ch
		int 21h
BEGIN ENDP
CODE ENDS

AStack SEGMENT STACK
	dw 128 dup(0)
Astack ENDS

DATA SEGMENT
	IS_INTERRUPT_LOADED db 0
	PARAMETER db 0
	IF_INTERRUPT_SET db 'Interrupt already set $'
	IF_INTERRUPT_NOTSET db 'Interrupt not yet set $'
	STR_UN db 'Interrupt already set, but the /un parameter is found $'
DATA ENDS
	END BEGIN