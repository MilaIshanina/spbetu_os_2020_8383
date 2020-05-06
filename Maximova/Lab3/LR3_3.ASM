COMMENT @
Максимова Анастасия, группа 8383, 3 лабораторная - 3 часть
@

CODE	        SEGMENT
		        ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
		        ORG 100H
			
START:	        JMP		MAIN

EOF				EQU		'$'
SETPRECISION	EQU		40
SETPR			EQU     20

;ДАННЫЕ
PROG			DB	0DH, 0AH, 0AH, 'Programm: third.	',                            EOF
AVAILABLE_MEM	DB	0DH, '1. Amount of available memory:           bytes.',           EOF 			;количество доступной памяти
FR_MEM			DB  0DH, '2. Free memory!',                                           EOF 			;количество доступной памяти
GIVE_MEM		DB  0DH, '3. Program requests memory',                                EOF 
EXTENDED_MEM	DB	0DH, 0AH, 0AH, '4. Extended memory size:                kbytes.', EOF 	        ;размер расширенной памяти

MCB             DB  0DH, 0AH, 0AH,'5. Memory management block chain:',                EOF 	
DELIMITER		DB  0DH, 0AH,'-----------------------------------------------',       EOF 
TYPE1		    DB  0DH, 0AH, 'MCB TYPE: 4Dh    ',                                    EOF 	
TYPE2		    DB  0DH, 0AH, 'MCB TYPE: 5Ah    ',                                    EOF           ;5Ah - last

CASE1_			DB	0DH, 0AH, 'FREE AREA - address:                0000h',            EOF								
CASE2_			DB	0DH, 0AH, 'BELONGS DRIVER OS XMS UMB - address:0006h',            EOF				
CASE3_			DB	0DH, 0AH, 'TOP MEMORY DRIVER  - address:       0007h',            EOF
CASE4_			DB	0DH, 0AH, 'BELONGS MS DOS - address:           0008h',            EOF
CASE5_			DB	0DH, 0AH, 'CONTROL UNIT 386MAX UMB - address:  FFFAh',            EOF
CASE6_			DB	0DH, 0AH, 'BLOCKED 386MAX - address:           FFFDh',            EOF
CASE7_			DB	0DH, 0AH, 'BELONGS 386MAX UMB - address:       FFFEh',            EOF
CASE_			DB	0DH, 0AH,  'Segment address PSP:                   h',            EOF	

SIZE_MEM		DB	0DH, 0AH, 'Memory size:         bytes.',                          EOF	
LAST			DB 	0DH, 0AH, 'Last eight bytes:  ',                                  EOF	 

;ПРОЦЕДУРЫ
;----------------------------------------------------------
TETR_TO_HEX		PROC	NEAR										
				and    AL, 0Fh											
				cmp    AL, 09											
				jbe    NEXT												
				add    AL, 07											
NEXT:	  		add	   AL, 30h											
				ret
TETR_TO_HEX    ENDP		
;-----------------------------------------------------------
BYTE_TO_HEX		PROC	NEAR										;байт в AL переводится в два символа шестн. числа в AX
				push    CX
				mov     AH, AL
				call    TETR_TO_HEX
				xchg    AL, AH
				mov     CL, 4
				shr     AL, CL
				call    TETR_TO_HEX									;в AL - старшая цифра
				pop     CX											;в AH - младшая
				ret
BYTE_TO_HEX		ENDP
;-----------------------------------------------------------
WRD_TO_HEX		PROC	NEAR										;перевод в 16 с/с 16-ти разрядного числа
																	;в АХ - число, DI - адрес последнего символа
				push	BX
				mov		BH, AH
				call	BYTE_TO_HEX
				mov		[DI], AH
				dec		DI
				mov		[DI], AL
				dec		DI
				mov		AL, BH
				call	BYTE_TO_HEX
				mov		[DI], AH
				dec		DI
				mov		[DI], AL
				pop		BX
				ret
WRD_TO_HEX		ENDP
;-----------------------------------------------------------
BYTE_TO_DEC		PROC NEAR
				push 	CX
				push 	DX
				xor 	AH,AH
				xor 	DX,DX
				mov 	CX,10
loop_bd:		
				div		CX
				or 		DL,30h		 ; перевод в ascii
				mov 	[SI],DL
				dec 	SI
				xor 	DX,DX
				cmp 	AX,10
				jae 	loop_bd
				cmp 	AL,00h
				je 		end_l
				or 		AL,30h		 
				mov 	[SI],AL
end_l:	
				pop DX
				pop CX
				ret
BYTE_TO_DEC ENDP
;-----------------------------------------------------------
GET_WRD_DEC		PROC 	NEAR 		 ; из BYTE_TO_DEC 

				push 	CX
				push 	DX
				
				mov 	CX, 10
loop_wd:		
				div		CX
				or 		DL, 30h		 ; перевод в ascii
				mov 	[SI], DL
				dec 	SI
				xor 	DX, DX
				
				cmp 	AX, 10		 
				jae 	loop_wd	
				
				cmp 	AL, 00h		  
				je 		end_wb
				
				or 		AL, 30h		  
				mov 	[SI], AL
end_wb:	
				pop DX
				pop CX
				retn
				
GET_WRD_DEC 	ENDP
;-----------------------------------------------------------
PRINTF		PROC	NEAR
			push    AX
			mov		AH, 09h
			int 	21h
			pop     AX
			retn
PRINTF		ENDP
;-----------------------------------------------------------
GET_A_MEM		PROC	NEAR			;1 ЗАДАНИЕ - РАСПЕЧАТАТЬ КОЛИЧЕСТВО ДОСТУПНОЙ ПАМЯТИ В 10 С.С.
			
				push	DX
				push	AX
				push	BX
				push    SI
				
				mov     DX, OFFSET  PROG
				call	PRINTF	
				xor		DX, DX
				
				mov		SI, OFFSET AVAILABLE_MEM	
			    add     SI, OFFSET SETPRECISION	
				
				mov		AH, 04Ah		;изменить размер блока память
				mov		BX, 0FFFFh		;заведомо большая память
				int		21h				;в BX будет лежать максимальный размер доступный для этого блока
				
				mov		AX, 10h
				mul		BX				;параграф
				call    GET_WRD_DEC		;перевод в 10 с с 
				
				mov     DX, OFFSET AVAILABLE_MEM
				call	PRINTF		
			
				pop     SI
				pop		BX
				pop 	AX
				pop		DX

				retn
GET_A_MEM		ENDP
;-----------------------------------------------------------
GET_E_MEM		PROC	NEAR			;2 ЗАДАНИЕ - РАСПЕЧАТАТЬ РАЗМЕР РАСШИРЕННОЙ ПАМЯТИ В 10 С.С.
				push    AX
				push    BX
				push    DX
				push    SI
				
				mov		SI, OFFSET EXTENDED_MEM	
			    add     SI, OFFSET SETPRECISION
				
				xor		DX, DX
				mov		AL, 30h     	;запись адреса ячейки CMOS
				out		70h, AL
				in      AL, 71h     	;чтение младшего байта
				mov     BL, AL			;размер расширенной памяти
				
				mov     AL, 31h			;запись адреса ячейки CMOS
				out     70h, AL
				in      AL, 71h			;чтение старшего байта
				mov     AH, AL			;размер расширенной памяти
				mov     Al, BL

				call    GET_WRD_DEC		;перевод в 10 с с 
				
				mov     DX, OFFSET EXTENDED_MEM	
				call	PRINTF
				
				pop     SI
				pop     DX
				pop     BX
				pop     AX
				
				retn
GET_E_MEM		ENDP
;-----------------------------------------------------------
START_			PROC	NEAR			
				push    DX
				push	AX
				push    CX
				push    SI
		
				mov     DX, OFFSET DELIMITER
				call	PRINTF 
				
				cmp		AX, 4Dh		     ;печать типа		 
				jne		cout
				mov     DX, OFFSET TYPE1
				jmp     exit
cout:			
				mov     DX, OFFSET TYPE2		
exit:		
				call	PRINTF
				pop     SI
				pop     CX
				pop		AX
				pop     DX
				retn
START_			ENDP
;-----------------------------------------------------------
GET_ADRESS		PROC	NEAR
				push	AX
				push	ES
				push	DX
				push	DI
				
				mov     AX, ES:[01h]
				
				cmp		AX, 0000h
				jne     case2
				mov     DX, OFFSET CASE1_
				jmp		write			
case2:				
				cmp		AX, 0006h
				jne     case3
				mov     DX, OFFSET CASE2_
				jmp		write			
case3:				
				cmp		AX, 0007h
				jne     case4
				mov     DX, OFFSET CASE3_
				jmp		write
case4:		
				cmp		AX, 0008h
				jne     case5
				mov     DX, OFFSET CASE4_
				jmp		write
case5:				
				cmp		AX, 0FFFAh
				jne     case6
				mov     DX, OFFSET CASE5_
				jmp		write
case6:	
				cmp		AX, 0FFFDh
				jne     case7
				mov     DX, OFFSET CASE6_
				jmp		write		
case7:		
				cmp		AX, 0FFFEh
				jne     case0
				mov     DX, OFFSET CASE7_
				jmp		write			
case0:			
				xor		DI, DI
				xor		DX, DX
				mov		DI, OFFSET CASE_	
			    add     DI, OFFSET SETPRECISION	
				call	WRD_TO_HEX
				mov		DX, OFFSET CASE_	
write:
				call	PRINTF
end_a:
				pop		DI
				pop		DX
				pop 	ES
				pop 	AX
				
				retn
GET_ADRESS		ENDP
;-----------------------------------------------------------
GET_SIZE_MEM	PROC	NEAR
				push	SI
				push	BX
				push	ES
				push	AX
				push	DX
				
				mov		SI, OFFSET SIZE_MEM	
			    add     SI, OFFSET SETPR
				
				mov     BX, ES:[03h]	;размер участка в параграфах - перевести в 10 с/с
				
				mov		AX, 10h
				mul		BX				;параграф
				call    GET_WRD_DEC		;перевод в 10 с с 
				
				mov     DX, OFFSET SIZE_MEM	
				call	PRINTF		
				
				pop		DX
				pop		AX
				pop		ES
				pop		BX
				pop		DX
				retn
GET_SIZE_MEM	ENDP
;-----------------------------------------------------------
GET_SYMBOLS		PROC	NEAR
				push	DX
				push	DI
				push 	CX
				push	AX
				push	ES
				
				mov     DX, OFFSET LAST
				call	PRINTF 
				
				mov     DI, 0
				mov		CX, 8
symbol:	
				xor 	AX, AX
				mov		AH, 02h
				mov		DL, ES:[08h + DI]  ;08h - там лежат символы
				int 	21h
				inc		DI
				loop	symbol
				
				pop		ES
				pop		AX
				pop		CX
				pop		DI
				pop		DX
				retn
GET_SYMBOLS		ENDP
;-----------------------------------------------------------
GET_MCB			PROC	NEAR			     ;3 ЗАДАНИЕ - ВЫВОД ЦЕПОЧКИ БЛОКОВ УПРАВЛЕНИЯ ПАМЯТЬЮ 
				push	DX
				push	AX
				push	ES
				push	BX
				
				mov     DX, OFFSET MCB
				call	PRINTF
				
				mov		AH, 52h			     ;доступ к указателю на структуру 
				int 	21h				     ;list of lists
				mov     AX, ES:[BX - 02h]	 ;получение адреса
				mov 	ES, AX			     ;первого MCB
replay:				
				xor		AX, AX
				mov		AL, ES:[00h]	     ;type MCB
				push	AX				
				
				call	START_
				call 	GET_ADRESS
				call    GET_SIZE_MEM
				call	GET_SYMBOLS 
				
				pop		AX
				cmp		AX, 4Dh
				jne		end_MCB
				
				mov     AX, ES:[03h]	     ;размер участка в параграфах
				mov		BX, ES		         ;адрес начала	
				add     BX, AX			     ;адрес конца
				inc		BX				     ;в BX - адрес след элемента
				mov		ES, BX
				jmp		replay			
end_MCB:			
				pop		BX
				pop		ES
				pop		AX
				pop		DX
				retn
GET_MCB			ENDP
;-----------------------------------------------------------
FREE_MEMORY		PROC	NEAR			;освобождение памяти
				push	AX
				push	BX
				push	DX
				
				mov     DX, OFFSET FR_MEM
				call	PRINTF	
				
				mov		AH, 4Ah
				mov		BX,	OFFSET END_PR
				int 	21h
				
				pop     DX
				pop		BX
				pop		AX
				retn
FREE_MEMORY		ENDP
;-----------------------------------------------------------
GIVE_ME_MEMORY	PROC	NEAR			;запрашивание памяти
				push	AX
				push	BX
				push	DX
				
				mov     DX, OFFSET GIVE_MEM
				call	PRINTF	
				
				mov 	AH, 48h
				mov		BX, 1000h 	    ;1024*64/16 в 10
				int 	21h
				
				pop		DX
				pop		BX
				pop		AX
				retn
GIVE_ME_MEMORY	ENDP
;-----------------------------------------------------------
MAIN:		
		call	GET_A_MEM
		call	FREE_MEMORY
		call	GIVE_ME_MEMORY
		call    GET_E_MEM
		call	GET_MCB

        ;выход в DOS
		sub		AL, AL
		mov		AH, 4Ch
		int		21h
END_PR	DB	0
CODE	ENDS					
		END 	START	