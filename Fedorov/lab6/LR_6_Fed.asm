

;ZSEG SEGMENT 
;фиктивный сегмент
;ZSEG ENDS

; Программа "родителя"

DATA SEGMENT
    CODE_ db '    ', 13,10,'$'
	KEEP_SS DW 0  ;переменная для SS
    KEEP_SP DW 0  ;переменная для SP
	KEEP_PSP DW 0 ;переменная для PSP           
	FILENAME_ DB 'LR_2_6.COM', 0            
	FILEPATH DB 128 DUP(0)
	PARAMETERS DW 7 DUP(0) 
	MEM_FLAG DB 1

   
  ; Load programm errors (CF = 1)
    LOAD_ERR_1 db 'Invalid function numver',13,10,'$'
	LOAD_ERR_2 db 'File not found',13,10,'$'
	LOAD_ERR_5 db 'Disk error',13,10,'$'
	LOAD_ERR_8 db 'Out of memory',13,10,'$'
	LOAD_ERR_10 db 'Invalid enviroment str',13,10,'$'
	LOAD_ERR_11 db 'Invalid format',13,10,'$'
	
  ; Succes load (CF = 0)
	NORMAL_CODE_0 db 13,10,'Normal end:$'
	NORMAL_CODE_1 db 'Ctrl-Break end',13,10,'$'
	NORMAL_CODE_2 db 'Device error',13,10,'$'
	NORMAL_CODE_3 db '  31H End',13,10,'$'
	
  ; Memory error
    MEMORY_ERR_7 db 'Memory block was destroyed',13,10,'$'
	MEMORY_ERR_8 db 'Out of memory to function',13,10,'$'
	MEMORY_ERR_9 db 'Invalid memory block`s address',13,10,'$'
    	
	END_STR  EQU '$'

	dsize=$-CODE_        ;размер сегмента данных
DATA ENDS


	astack segment stack
	dw 64 dup(?)     
	astack ends         

	code segment 
	assume CS:CODE, DS:DATA, ss:astack 

CODES: 

WriteMsg  PROC  NEAR
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
WriteMsg  ENDP


BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP
;-------------------------------


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



;---------------------------------------------------------------------
PREPARE_MEMORY_SPACE PROC NEAR
	PUSH AX
	PUSH BX
	PUSH DX
    mov BX,((csize/16)+1)+256/16+((dsize/16)+1)+200/16  ; перевод в параграфы /16
	MOV AH,4Ah                                          ; psp + 64*2 stack
    int 21h     	
    JC MEMORY_ERROR                                     ;проверяем на ошибку   CF = 1
    MOV MEM_FLAG, 0
	JMP END_MEM_SPACE
MEMORY_ERROR:
	cmp ax, 7
	Jne else_if_1
	mov dx, offset MEMORY_ERR_7
	jmp print_err
else_if_1:
	cmp ax, 8
	jne else_if_2
	mov dx, offset MEMORY_ERR_8
	jmp print_err
else_if_2:
	mov dx, offset MEMORY_ERR_9
	jmp print_err
print_err:
    call WriteMsg
	mov MEM_FLAG, -1

END_MEM_SPACE:
	POP DX
	POP BX
	POP AX
	ret
PREPARE_MEMORY_SPACE ENDP
;---------------------------------------------------------------------



;---------------------------------------------------------------------	
GET_FILEPATH PROC NEAR
	PUSH DX
	PUSH AX
	PUSH DI
	PUSH SI
	PUSH ES
		
	mov KEEP_PSP, es
	mov es, es:[2CH]
	xor si, si
while_not_path:
	mov ax, es:[si]
	inc si
	cmp ax, 0
	jne while_not_path
	inc si
	inc si
	inc si
	xor di, di
		
while_path:
	mov dl, es:[si]
	cmp dl, 0
	je rewrite_name
	mov FILEPATH[di], dl
	inc SI
	inc di
	jmp while_path
		
rewrite_name:
    dec di
    cmp FILEPATH[di], '\'
    je filename__
    jmp rewrite_name	

filename__:
	inc di
	xor si, si
	
while_filename:
	mov dl,FILENAME_[si]
	mov FILEPATH[di], dl
	cmp dl, 0 
	je end_filepath
	inc si
	inc di
	jmp while_filename
		
end_filepath:	
	POP ES
	POP SI
	POP DI
	POP AX
	POP DX
	ret
GET_FILEPATH ENDP
;---------------------------------------------------------------------		



Main PROC FAR
	mov BX, DS
	mov AX, DATA
	mov DS, AX
	mov KEEP_PSP, BX
	call PREPARE_MEMORY_SPACE
	cmp MEM_FLAG, -1
	je END_MAIN1
	call GET_FILEPATH
	PUSH ES
	MOV KEEP_SP, SP
	MOV KEEP_SS, SS
    MOV BX, OFFSET PARAMETERS
    MOV DX, OFFSET FILEPATH     ;смещение - в DX
    MOV AX, SEG FILEPATH        ;сегмент - в DS
	MOV DS, AX 
    MOV AH, 4BH                 ;функция EXEC
    MOV AL, 0                   ;выбираем "загрузку и запуск"
    INT 21H                     ;запускаем задачу 
	MOV BX,AX
    MOV AX,DATA                 ;восстанавливаем DS
    MOV	DS,AX	
	MOV AX,BX
    MOV SS,KEEP_SS              ;восстанавливаем SS
    MOV SP,KEEP_SP              ;восстанавливаем SP
	POP ES
	JC ERROR_LOAD
NORMAL_LOAD:
    mov AH, 4Dh
	int 21h	
	cmp AH, 0
	jne normal_1
	mov DX, offset NORMAL_CODE_0
    call WriteMsg
    ;CBW
	mov dx, offset CODE_
    mov si, dx
    add si, 2
	call BYTE_TO_DEC
	call WriteMsg
	jmp END_MAIN1
  normal_1:
	cmp AH, 1
	jne normal_2
	mov DX, offset NORMAL_CODE_1
	call WriteMsg
	jmp END_MAIN1
  normal_2:
	cmp AH, 2
	jne normal_3
	mov DX, offset NORMAL_CODE_2
	call WriteMsg
	jmp END_MAIN1
  normal_3:
	cmp AH, 3
	mov DX, offset NORMAL_CODE_3
	call WriteMsg	
	jmp END_MAIN1
END_MAIN1:	
	jmp END_MAIN


ERROR_LOAD:
	cmp AX, 1
	jne else_2
	mov DX, offset LOAD_ERR_1
	jmp print_error
  else_2:
	cmp AX, 2
	jne else_5
	mov DX, offset LOAD_ERR_2
	jmp print_error
  else_5:
	cmp AX, 5
	jne else_8
	mov DX, offset LOAD_ERR_5
	jmp print_error
  else_8:
	cmp AX, 8
	jne else_10
	mov DX, offset LOAD_ERR_8
	jmp print_error
  else_10:
	cmp AX, 10
	jne else_11
	mov DX, offset LOAD_ERR_10
	jmp print_error	
  else_11:
	cmp AX, 11
	mov DX, offset LOAD_ERR_11
	jmp print_error
  print_error:
    call WriteMsg	
END_MAIN:
    mov AH, 4Ch
	int 21h
csize=$-CODES          
Main ENDP	
CODE ENDS
;ZSEG SEGMENT ;фиктивный сегмент
;ZSEG ENDS
END MAIN