TESTPC     SEGMENT
           ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   ORG 100H    ;обязательно!
START:     JMP MAIN

LEN_CLOSE_MEM  EQU 30
LEN_ENV_SEG EQU 28
;TAIL db 83 DUP(?)
STR_CLOSE_MEM db 13,10, "Address of close memory:             $" 
STR_ENV_SEG db 13,10, "Address of enviroment:             $" 
STR_TAIL db 13,10, "Tail comand_line: $"
STR_EMPTY_TAIL db " (nothing) $"
STR_ENVIROMENT_AREA db 13,10, "Enviroment: $"
STR_ENTER db 13,10, " $"
STR_PATH db 13,10, "Path: $"
ENTER_STR db 13,10, '$'
;ПРОЦЕДУРЫ
;-------------------------------

WRITE_STR PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE_STR ENDP
;-------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
; Funct lab_2

PRINT_ADDRESS_CLOSE_MEM PROC near
   push ax
   push dx
   mov ax, ds:[02h]                    ;в PSP 
   mov di, offset STR_CLOSE_MEM
   add di, LEN_CLOSE_MEM
   call WRD_TO_HEX
   mov dx, offset STR_CLOSE_MEM
   call WRITE_STR
   pop dx
   pop ax
   ret
PRINT_ADDRESS_CLOSE_MEM ENDP


PRINT_ADDRESS_ENVIROMENT  PROC near 
   push ax
   push dx
   mov ax, ds:[2Ch]               ;(44)
   mov di, offset STR_ENV_SEG
   add di, LEN_ENV_SEG
   call WRD_TO_HEX
   mov dx, offset STR_ENV_SEG
   call WRITE_STR
   pop dx
   pop ax
   ret
PRINT_ADDRESS_ENVIROMENT ENDP



PRINT_TAIL PROC near   
   push ax
   push dx
   mov dx, offset STR_TAIL
   call WRITE_STR
   mov cx, 0
   mov cl, ds:[80h]        ;число символов в хвосте
   cmp cl, 0
   je tail_empty
   mov di, 0
   xor dx,dx
 print_tail_cycle:
   mov dl, ds:[81h+di]   ;ds+81h+di сделать потом
   mov ah,02H
   int 21h
   inc di
   loop print_tail_cycle
   jmp end_print
tail_empty:
   mov dx, offset STR_EMPTY_TAIL
   call WRITE_STR
end_print: 
   pop dx
   pop ax
   ret
PRINT_TAIL ENDP



PRINT_PATH_ENVIROMENT PROC near
   push dx
   push ax
   push ds
   mov dx, offset STR_ENVIROMENT_AREA
   call WRITE_STR
   mov di, 0
   mov es, ds:[2Ch]
cycle_env:
   cmp byte ptr es:[di], 00h            ;mov dl, ds:[di] и сранивать dl  c 0
   je enter_                       ;==
   mov dl, es:[di]
   mov ah, 02h
   int 21h
   inc di
   jmp cycle_env
enter_:
   inc di
   cmp word ptr es:[di], 0001h
   je path_
   mov dx, offset STR_ENTER
   call WRITE_STR
   jmp cycle_env
path_:
   inc di
   inc di
   mov DX, offset STR_PATH
   call WRITE_STR
cycle_p:
   cmp byte ptr es:[di], 00h
   je end_print_p
   mov dl, es:[di]
   mov ah, 02h
   int 21h
   inc di
   jmp cycle_p
end_print_p:	
   mov dx, offset ENTER_STR
   call WRITE_STR
   pop dx
   pop ax
   pop ds
   ret
PRINT_PATH_ENVIROMENT ENDP



MAIN:
   call PRINT_ADDRESS_CLOSE_MEM
   call PRINT_ADDRESS_ENVIROMENT
   call PRINT_TAIL
   call PRINT_PATH_ENVIROMENT

   xor al, al
   mov ah, 01h
   int 21h  
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START
