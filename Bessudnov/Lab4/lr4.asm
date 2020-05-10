CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENDS

DATA    SEGMENT
	MES_LOADED DB  "Loaded already",10,13,"$"
	MES_NOT_LOADED     DB  "Not loaded",10,13,"$"
    IS_NOT_LOADED      DB  1
    IS_UN              DB  0
DATA    ENDS

;прерывание
MY_INT   PROC    FAR
        jmp     MY_INT_START
		INT_COUNTER        DB  "000 interrupts"
		ID                 DW  6506h
		KEEP_AX 	DW 0
		KEEP_SS 	DW 0
		KEEP_SP 	DW 0
		KEEP_IP 	DW 0
		KEEP_CS 	DW 0
		KEEP_PSP 	DW 0
		INT_STACK 	DW 128 dup(0)
		
    MY_INT_START:
		mov 	KEEP_AX, AX
		mov 	KEEP_SP, SP
		mov 	KEEP_SS, SS
		mov 	AX, SEG INT_STACK
		mov 	SS, AX
		mov 	AX, offset INT_STACK
		add 	AX, 256
		mov 	SP, AX
		push 	BX
		push 	CX
		push 	DX
		push 	SI
		push 	DS

		
		mov 	AX, seg INT_COUNTER
		mov 	DS, AX
        
    ;поставить курсор
        mov     AH, 03h
		mov     BH, 0h
		int     10h
        push    DX

        mov     AH, 02h
		mov     BH, 0h
		mov     DX, 1820h 
		int     10h

	;увеличить счетчик
		mov 	AX, SEG INT_COUNTER
		push 	DS
		mov 	DS, AX
		mov 	SI, offset INT_COUNTER
		add		SI, 2
		mov 	CX, 3
	MY_INT_CYCLE:
		mov 	AH, [SI]
		inc 	AH
		mov 	[SI], AH
		cmp 	AH, ':'
		jne 	MY_INT_END_CYCLE
		mov 	AH, '0'
		mov 	[SI], AH
		dec 	SI
		loop 	MY_INT_CYCLE		
	MY_INT_END_CYCLE:
		pop 	DS

	;печать счетчика
		push 	ES
		push	BP
        mov     AX, SEG INT_COUNTER
		mov     ES, AX
		mov     BP, offset INT_COUNTER
		mov     AH, 13h
		mov     AL, 1h
		mov 	BL, 2h
		mov     BH, 0
		mov     CX, 14
		int     10h

		pop		BP
		pop		ES
		

        pop     DX
        mov     AH, 02h
		mov     BH, 0h
		int     10h

		pop 	DS
		pop 	SI
		pop 	DX
		pop 	CX
		pop 	BX
		mov 	SP, KEEP_SP
		mov 	AX, KEEP_SS
		mov 	SS, AX
		mov 	AX, KEEP_AX
		mov 	AL, 20h
		out 	20h, AL
	iret
MY_INT    ENDP
MY_INT_END:
	
;проверка прерывания на загруженность
MY_INT_CHECK       PROC
		push    AX
		push    BX
		push    SI
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     SI, offset ID
		sub     SI, offset MY_INT
		mov     AX, ES:[BX + SI]
		cmp	    AX, ID
		jne     MY_INT_CHECK_END
		mov     IS_NOT_LOADED, 0
		
	MY_INT_CHECK_END:
		pop     SI
		pop     BX
		pop     AX
	ret
MY_INT_CHECK       ENDP
;загрузка прерывания
MY_INT_LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS

        mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg MY_INT
		mov     DX, offset MY_INT
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop		DS

        mov     DX, offset MY_INT_END
		mov     CL, 4h
		shr     DX, CL
		add		DX, 10Fh
		inc     DX
		xor     AX, AX
		mov     AH, 31h
		int     21h

        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
MY_INT_LOAD        ENDP
;выгрузка прерывания
MY_INT_UNLOAD      PROC
        CLI
		push    AX
		push    BX
		push    DX
		push    DS
		push    ES
		push    SI
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset MY_INT
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop 	DS
		
		mov 	AX, ES:[BX + SI + 4]
		mov 	ES, AX
		push 	ES
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h
		pop 	ES
		mov 	AH, 49h
		int 	21h
		
		STI
		
		pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX
		
	ret
MY_INT_UNLOAD      ENDP

;проверяем не был ли передан аргумент /un
UN_CHECK        PROC
        push    AX
		push    ES

		mov     AX, KEEP_PSP
		mov     ES, AX
		cmp     byte ptr ES:[82h], '/'
		jne     UN_CHECK_END
		cmp     byte ptr ES:[83h], 'u'
		jne     UN_CHECK_END
		cmp     byte ptr ES:[84h], 'n'
		jne     UN_CHECK_END
		mov     IS_UN, 1
		
	UN_CHECK_END:
		pop     ES
		pop     AX
		ret
UN_CHECK        ENDP

WRITE_STR    PROC    NEAR
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
    ret
WRITE_STR   ENDP

MAIN PROC
		push    DS
		xor     AX, AX
		push    AX
		mov     AX, DATA
		mov     DS, AX
		mov     KEEP_PSP, ES
		
		call    MY_INT_CHECK
		call    UN_CHECK
		cmp     IS_UN, 1
		je      UNLOAD
		mov     AL, IS_NOT_LOADED
		cmp     AL, 1
		je      LOAD
		mov     DX, offset MES_LOADED
		call    WRITE_STR
		jmp     MAIN_END
	LOAD:;загружаем перрывание
		call    MY_INT_LOAD
		jmp     MAIN_END
	UNLOAD: ;выгрузка перрывания, если передали /un
		cmp     IS_NOT_LOADED, 1
		je     NOT_EXIST
		call    MY_INT_UNLOAD
		jmp     MAIN_END
	NOT_EXIST:
		mov     DX, offset MES_NOT_LOADED
		call    WRITE_STR
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP
CODE    ENDS
END 	MAIN  