CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

INTER   PROC    FAR
        jmp     INTER_START
	INTER_DATA:
		COUNTER            DB  "000 interrupts"
		SIGNATURE          DW  3158h
		KEEP_IP 	       DW  0
		KEEP_CS 	       DW  0
		KEEP_PSP 	       DW  0
		
    INTER_START:
		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
        push    ES
        push    DS
		mov 	AX, seg COUNTER
		mov 	DS, AX
        
    SET_CURSOR:
        mov     AH, 03h
		mov     BH, 0h
		int     10h
        push    DX

        mov     AH, 02h
		mov     BH, 0h
		mov     DX, 1820h 
		int     10h

	INCREASE:
		mov 	AX, SEG COUNTER
		push 	DS
		mov 	DS, AX
		mov 	SI, offset COUNTER
		add		SI, 2
		mov 	CX, 3
	INTER_CYCLE:
		mov 	AH, [SI]
		inc 	AH
		mov 	[SI], AH
		cmp 	AH, ':'
		jne 	INTER_END_CYCLE
		mov 	AH, '0'
		mov 	[SI], AH
		dec 	SI
		loop 	INTER_CYCLE		
	INTER_END_CYCLE:
		pop 	DS

	PRINT_COUNTER:
		push 	ES
		push	BP
        mov     AX, SEG COUNTER
		mov     ES, AX
		mov     BP, offset COUNTER
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

		pop     DS
		pop     ES
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX

		mov     AL, 20h
		out     20h, AL
	iret
INTER    ENDP
    INTER_END:

INTER_CHECK       PROC
		push    AX
		push    BX
		push    SI
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     SI, offset SIGNATURE
		sub     SI, offset INTER
		mov     AX, ES:[BX + SI]
		cmp	    AX, SIGNATURE
		jne     INTER_CHECK_END
		mov     IS_LOADED, 1
		
	INTER_CHECK_END:
		pop     SI
		pop     BX
		pop     AX
	ret
INTER_CHECK       ENDP

INTER_LOAD        PROC
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
        mov     AX, seg INTER
		mov     DX, offset INTER
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop		DS

        mov     DX, offset INTER_END
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
INTER_LOAD        ENDP

INTER_UNLOAD      PROC
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
		sub 	SI, offset INTER
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
INTER_UNLOAD      ENDP

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
		
		call    INTER_CHECK
		call    UN_CHECK
		cmp     IS_UN, 1
		je      UNLOAD
		mov     AL, IS_LOADED
		cmp     AL, 1
		jne     LOAD
		mov     DX, offset STR_LOADED_ALREADY
		call    WRITE_STR
		jmp     MAIN_END
	LOAD:
		call    INTER_LOAD
		jmp     MAIN_END
	UNLOAD:
		cmp     IS_LOADED, 1
		jne     NOT_EXIST
		call    INTER_UNLOAD
		jmp     MAIN_END
	NOT_EXIST:
		mov     DX, offset STR_NOT_LOADED
		call    WRITE_STR
	MAIN_END:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENDS

DATA    SEGMENT
	STR_LOADED_ALREADY DB  "Interruption loaded already ",10,13,"$"
	STR_NOT_LOADED     DB  "Interruption isn't loaded",10,13,"$"
    IS_LOADED          DB  0
    IS_UN               DB  0
DATA    ENDS

END 	MAIN 
