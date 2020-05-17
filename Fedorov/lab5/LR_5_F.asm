
code segment 
	assume cs:code, ds:data, ss:astack 

RESIDENT_INTER PROC FAR
start:  jmp begin
    SIGNATURE_INTER dw 777h
	SEGMENT_ dw 0
    KEEP_IP dw 0
	KEEP_CS dw 0
	REQ_KEY1 db 2Dh    ; x
	REQ_KEY2 db 2Ch    ;Z
    mem dw 0 
    char db 0	
	ss_seg dw 0
	ss_offs dw 0
	LOCAL_STACK dw 100 dup (0)
	TOP_STACK=$
begin:
   mov ss_seg,ss
   mov ss_offs,sp
   mov mem, ax  
              ;сохранение кадра стека прерванной задачи
   mov ax, seg LOCAL_STACK
   mov ss, ax
   mov sp, offset TOP_STACK
   mov ax, mem     
   push es   
   push ax		
   push bx
   push cx
   push dx
   push ds
verify_caps:
   mov AH,2           
   int 16H                ;байт статуса
   test AL,01000010B      ;проверка на caps и/или левый shift 
   jnz call_std           ;если 0, то CAPS выключен   

   xor ax, ax
   in al,60H              ;читать ключ
   cmp al,REQ_KEY1        
   je do_req1             
   cmp al, REQ_KEY2          
   je do_req2
call_std:                 ;вызов стандартного
   pushf        ;;;;;;;;;;;;;;iret выталкивает ip,cs и flags
   call dword ptr cs:KEEP_IP
   jmp end_resident

do_req1:
   mov char, 0DEh
   jmp next_

do_req2:
   mov char, 0BAh
   jmp next_
   
; noise:
   ; CLI
   ; push ax
   ; push dx
   ; mov ah, 2
   ; mov dl, 7
   ; int 21h
   ; pop dx
   ; pop ax
   ; jmp next_
   ; STI
next_:
   in al,61H         ;взять значение порта управления клавиатурой
   mov ah, al        ;сохранить его  
   or al, 80H        ;установить бит разрешения для клавиатуры   
   out 61H, al       ;и вывести его в управляющий порт 
   xchg ah, al       ;извлечь исходной значение порта   
   out 61H, al       ;и записать его обратно  
   mov al, 20H     
   out 20H, al 

print_bufer:
   mov ah, 05h 
   mov cl, char
   mov ch, 00h	
   int 16h
   or al, al
   jnz skip
   jmp end_resident
   
skip:
   CLI                   ;запрещаем прерывания
   SUB AX,AX             ;обнуляем регистр
   MOV ES,AX             ;добавочный сегмент - с начала памяти
   MOV AL,ES:[41AH]      ;берем указатель на голову буфера
   MOV ES:[41CH],AL      ;посылаем его в указатель хвоста
   STI                   ;разрешаем прерывания   
   JMP print_bufer
	
end_resident:
   pop ds
   pop dx
   pop cx
   pop bx
   pop ax
   pop es
   mov AL, 20H
   OUT 20H, AL    
   xor ax, ax
   mov ax, ss_seg
   mov ss, ax
   mov sp, ss_offs
   mov ax, mem
   IRET
LAST_BYTE:	
RESIDENT_INTER ENDP


WriteMsg  PROC  NEAR
   push ax
   mov ah,09h
   int 21h
   pop ax
   ret
WriteMsg  ENDP


VERIFY_LOADING PROC        
   mov AH, 35h
   mov AL, 09H              ;Номер прерывания
   int 21h                  ; ES:BX = адрес обработчика прерывания 
   mov si, offset SIGNATURE_INTER
   sub si, offset RESIDENT_INTER
   mov ax, es:[bx+si]
   cmp ax, SIGNATURE
   je already_load
   call DO_RESIDENT
   ;jmp end_
already_load:
   call UNLOAD_RESIDENT
end_:
   ret
VERIFY_LOADING ENDP


DO_RESIDENT PROC	
    mov ax, SEGMENT_
	mov es, ax
	mov al, es:[80h]
	cmp al, 0
	je do_res
    mov al, es:[81h+1]     ; es на psp
    cmp al, '/'
    jne do_res
    mov al, es:[81h+2]
    cmp al, 'u'
    jne do_res
    mov al, es:[81h+3]
    cmp al, 'n'
    jne do_res	 	
	mov dx, offset message2
	call WriteMsg
	jmp end_do_res
do_res:	
    ;-----------------------
	MOV AH, 35h         ; функция получения вектора
	MOV AL, 09H         ; номер вектора  
	INT 21h
	MOV KEEP_IP, BX     ; запоминание смещения
	MOV KEEP_CS, ES     ; и сегмента вектора прерывания
	;---------------установка прерывания
    PUSH DS
	MOV DX, OFFSET RESIDENT_INTER       ; смещение для процедуры в DX
	MOV AX, SEG RESIDENT_INTER          ; сегмент процедуры
	MOV DS, AX                   ; помещаем в DS
	MOV AH, 25H                  ; функция установки вектора
	MOV AL, 09H                  ; номер вектора 
	INT 21H                      ; меняем прерывание
	POP DS	
	mov DX, offset LAST_BYTE
	mov CL, 4
	shr DX, CL
	inc DX
	add dx, 10h
	xor AX, AX
	mov AH, 31h
	int 21H
	mov dx, offset message1
	call WriteMsg
end_do_res:	
	xor ax, ax
	mov ah, 4CH
	int 21h
	;ret
DO_RESIDENT ENDP



UNLOAD_RESIDENT PROC
	 push AX
	 push BX
	 push DX
	 push DS
	 push ES

     mov ax, SEGMENT_
	 mov es, ax
	 mov al, es:[80h]
	 cmp al, 0
	 je error_tail
     mov al, es:[81h+1]     ; es на psp
     cmp al, '/'
     jne error_tail
     mov al, es:[81h+2]
     cmp al, 'u'
     jne error_tail
     mov al, es:[81h+3]
     cmp al, 'n'
     jne error_tail
	 mov dx, offset message4
	 call WriteMsg	 
	 mov AH, 35h
	 mov AL, 09H
	 int 21h	 
	 mov si, offset KEEP_IP
	 sub si, offset RESIDENT_INTER
	 mov dx, es:[bx+si]
	 mov ax, es:[bx+si+2]
	 CLI
	 mov ds, ax
	 mov AH, 25H
	 mov AL, 09H
	 int 21H	
	 STI	
	 mov ax, es:[bx+si-2]
	 mov es, ax
	 mov ax, es:[2CH]
	 push es
	 mov es, ax
	 mov AH, 49H
	 int 21H
	 pop es
	 mov AH, 49H
	 int 21H
	 jmp end_unload1	 
error_tail:
     mov dx, offset message3
	 call WriteMsg
	 jmp end_unload

end_unload1:
	 ; mov dx, offset message4
	 ; call WriteMsg
end_unload:   
	 pop ES
	 pop DS
	 pop DX
	 pop BX
	 pop AX
	ret
UNLOAD_RESIDENT ENDP


MAIN PROC 
	xor ax, ax
	mov ax, data
	mov ds, ax
	mov SEGMENT_, es
	call VERIFY_LOADING
end_main:
	;CLC
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
code ENDS


data segment 
 bool_resident db 0
 bool_var db 0
 message1 db 'INTERRUPT LOAD!',10,13,'$'
 message2 db 'NOT LOAD$'
 message3 db 'INTERRUPT ALREADY LOAD!$'
 message4 db 'INTERRUPT UNLOAD!',10,13,'$'
 SIGNATURE dw 777h
data ends

astack segment stack
dw 128 dup(?)     ;: для исключения возможного взаимного влияния системных и  пользовательских  
astack ends       ; прерываний  рекомендуется  отвести  в программе под стек не менее 1К байт.

END MAIN



