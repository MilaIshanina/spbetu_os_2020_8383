CODE SEGMENT
	ASSUME CS:CODE
	
MAIN PROC FAR
		push AX
		push DX
		push DS
		push DI
		
		mov AX, CS
		mov DS, AX
		mov DI, offset ADRESS
		add DI, 18
		call WRD_TO_HEX
		mov DX, offset SEPARATOR
		call WRITE_STR
		MOV DX, offset ADRESS
		call WRITE_STR
		mov DX, offset SEPARATOR
		call WRITE_STR
		
		pop DI
		pop DS
		pop DX
		pop AX
		retf
MAIN ENDP
	
ADRESS db "OVL1 adress:        ", 13, 10, "$"
SEPARATOR db "---------------------", 13, 10, "$"

WRITE_STR PROC NEAR
		push AX
		
		mov AH, 09h
		int 21h

		pop AX
		ret
WRITE_STR ENDP


TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
next:
		add AL,30h
		ret
TETR_TO_HEX ENDP


BYTE_TO_HEX PROC NEAR		
		push 	cx
		mov 	ah, al
		call 	TETR_TO_HEX
		xchg 	al,ah
		mov 	cl,4
		shr 	al,cl
		call 	TETR_TO_HEX 	
		pop 	cx 				
		ret
BYTE_TO_HEX ENDP


WRD_TO_HEX PROC NEAR 
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		xor		ah,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP

CODE ENDS
END MAIN   