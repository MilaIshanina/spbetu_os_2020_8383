OVR  SEGMENT 
ASSUME CS:OVR, DS:NOTHING

OVERLAY PROC FAR           ;всегда далекая процедура
	PUSH AX
	PUSH DX
	PUSH DI
	PUSH DS                ;храним DS вызывающей программы	
	MOV AX, CS
	MOV DS, AX	
	MOV DI, offset MESSAGE
	ADD DI, 16
	CALL WRD_TO_HEX
	MOV DX, offset MESSAGE
	CALL WriteMsg	
	POP DS                 ;восстанавливаем DS при завершении
	POP DI
	POP DX
	POP AX	
	RETF
OVERLAY ENDP

MESSAGE db 'It`s ovr-2:          ',13,10,'$'

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP

WriteMsg  PROC  NEAR
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
WriteMsg  ENDP

 
OVR ENDS
END OVERLAY
