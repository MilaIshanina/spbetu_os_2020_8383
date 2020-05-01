code segment 
	assume cs:code, ds:data, ss:astack 

RESIDENT_INTER PROC FAR
start:  jmp begin
    KEEP_IP dw 0
	KEEP_CS dw 0
    SEGMENT_ dw 0
    COUNT dw 0
	SIGNATURE_INTER dw 777h
    mem dw 0             
	ss_seg dw 0
	ss_offs dw 0
	LOCAL_STACK dw 64 dup (0)
	TOP_STACK=$
begin:
   mov ss_seg,ss
   mov ss_offs,sp
   mov mem, ax
   
   CLI               ;сохранение кадра стека прерванной задачи
   mov ax,cs
   mov ss,ax
   mov sp,offset TOP_STACK
   STI
   
   mov ax, mem  
   push ax		
   push bx
   push cx
   push dx
getCurs:
   mov ah,03h
   mov bh,0h
   int 10h
  ;выход: DH,DL = текущие строка, колонка
   push dx    
setCurs:
   mov ah,02h
   mov bh,0h
   mov dh,14h
   mov dl,30h   ;DH,DL = строка, колонка
   int 10h      ;выполнение 
  
   push bx
   push ax                    
   inc COUNT
   mov ax, COUNT
   xor cx,cx
   mov bx,10 
print_count:
   xor dx,dx
   div bx
   push dx
   inc cx
   test ax,ax
   jnz print_count  ;ZF = 0 
   mov ah, 02h
print_num:
   pop dx
   add dl, '0'
   int 21h
loop print_num
end_inter:
   pop bx
   pop ax  
   pop dx
retCurs:
   mov ah,02h
   mov bh,0h
   int 10h
   pop dx
   pop cx
   pop bx
   xor ax, ax
   mov ax, ss_seg
   mov ss, ax
   pop ax
   mov sp, ss_offs
   
   mov AL, 20H
   OUT 20H, AL
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


;---------------------
outputAL PROC
	;call setCurs
	push ax
	push bx
	push cx
	mov ah, 09h   ;писать символ в текущей позиции курсора
	mov bh, 0     ;номер видео страницы
	mov cx, 1     ;число экземпляров символа для записи
	int 10h      ;выполнить функцию
	pop cx
	pop bx
	pop ax
	ret
outputAL ENDP
;---------------------

VERIFY_TAIL PROC near
   push ax
   push cx   
   push es
   mov al, es:[81h+1]     ; es на psp
   cmp al, '/'
   jne error_tail
   mov al, es:[81h+2]
   cmp al, 'u'
   jne error_tail
   mov al, es:[81h+3]
   cmp al, 'n'
   jne error_tail
   inc bool_var
   jmp end_p
error_tail:
   mov bool_var, 0
end_p:
   pop es
   pop cx
   pop ax
   ret
VERIFY_TAIL ENDP



VERIFY_LOADING PROC
   push ax
   push bx
   push si
   push es           
   mov AH, 35h
   mov AL, 1Ch;Номер прерывания
   int 21h
   mov si, offset SIGNATURE_INTER
   sub si, offset RESIDENT_INTER
   mov ax, es:[bx+si]
   cmp ax, SIGNATURE
   jne end_
   inc bool_resident
end_:
   pop es              
   pop si
   pop bx
   pop ax
   ret
VERIFY_LOADING ENDP


DO_RESIDENT PROC
	push ax
	push bx
	push dx
	push es		
    ;-----------------------
	MOV AH, 35h        ; функция получения вектора
	MOV AL, 1CH        ; номер вектора  
	INT 21h
	MOV KEEP_IP, BX     ; запоминание смещения
	MOV KEEP_CS, ES     ; и сегмента вектора прерывания
	;---------------установка прерывания
    PUSH DS
	MOV DX, OFFSET RESIDENT_INTER       ; смещение для процедуры в DX
	MOV AX, SEG RESIDENT_INTER          ; сегмент процедуры
	MOV DS, AX                   ; помещаем в DS
	MOV AH, 25H                  ; функция установки вектора
	MOV AL, 1CH                  ; номер вектора 
	INT 21H                      ; меняем прерывание
	POP DS
	mov DX, offset LAST_BYTE
	add DX, 10Fh                 ;100h + 15(Fh) при /16 в большую сторону
	mov CL, 4
	shr DX, CL
	inc DX
	xor AX, AX
	mov AH, 31h
	int 21h
	pop es
	mov dx, offset message1
	call WriteMsg
	pop dx
	pop bx
	pop ax
	ret
DO_RESIDENT ENDP



UNLOAD_RESIDENT PROC
	 push AX
	 push BX
	 push DX
	 push DS
	 push ES
	 mov AH, 35h
	 mov AL, 1Ch
	 int 21h
     mov dx, es:KEEP_IP
     mov ax, es:KEEP_CS
     CLI
	 push DS
	 mov DS, AX
	 mov AH, 25h
	 mov AL, 1Ch
	 int 21h
	 pop DS
	 STI
     mov ax, es:SEGMENT_
	 mov es, ax
	 push ES
	 mov AX, ES:[2Ch]
	 mov ES, AX
	 mov AH, 49h   ;функция освобождения памяти
	 int 21h		 
	 pop ES
	 mov AH, 49h
	 int 21h		
	 pop ES
	 pop DS
	 mov dx, offset message4
	 call WriteMsg
	 pop DX
	 pop BX
	 pop AX
	ret
UNLOAD_RESIDENT ENDP


MAIN PROC FAR
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov SEGMENT_, es	
    call VERIFY_TAIL 	
	call VERIFY_LOADING 
	cmp bool_var, 0
if_:je else_unload
    cmp bool_resident, 0
	je not_load 
	call UNLOAD_RESIDENT
	jmp end_main
not_load:
	mov dx, offset message2
	call WriteMsg
	jmp end_main	
else_unload:
	cmp bool_resident, 0
	ja already
	call DO_RESIDENT
	jmp end_main
already:
	mov dx, offset message3
	call WriteMsg
	jmp end_main
end_main:
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
dw 128 dup(?)     
astack ends       

END MAIN
