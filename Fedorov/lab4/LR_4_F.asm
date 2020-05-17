code segment 
	assume cs:code, ds:data, ss:astack 

RESIDENT_INTER PROC FAR
start:  jmp begin
	SIGNATURE_INTER dw 777h
	SEGMENT_ dw 0
    KEEP_IP dw 0
	KEEP_CS dw 0
    COUNT dw 0
    mem dw 0 
    mem_dx dw 0
	ss_seg dw 0
	ss_offs dw 0
	LOCAL_STACK dw 100 dup (0)
	TOP_STACK=$
begin:
   mov ss_seg,ss
   mov ss_offs,sp
   mov mem, ax
   mov ax, seg LOCAL_STACK
   mov sp, offset TOP_STACK
   mov ax, mem  
   push ax		
   push bx
   push cx
   push dx
   push ds
   push es 
   mov ax, cs
   mov ds, ax
   mov es, ax
   cmp CS:COUNT, 7920h
   jne next_
   mov CS:COUNT, 0
next_:

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
   mov mem_dx, dx
   int 10h      ;выполнение                 
   inc CS:COUNT
   mov ax, CS:COUNT
   xor cx,cx
   mov bx,10 
print_count:
   xor dx,dx
   div bx
   push dx
   inc cx
   test ax,ax
   jnz print_count  ;ZF = 0 

print_num:
   pop dx
   push cx
   add dl, '0'
   mov al,dl
   mov ah,09h
   mov bh, 0
   mov cx,1
   mov dx, mem_dx
   add dl, 1
   int 10h
   mov ah, 02h
   int 10h
   mov mem_dx, dx
   pop cx
loop print_num


   pop dx 
retCurs:
   mov ah,02h
   mov bh,0h
   int 10h

   pop es
   pop ds

   pop dx
   pop cx
   pop bx
   pop ax
  
   mov AL, 20H
   OUT 20H, AL
   
   xor ax,ax
   mov ax, ss_seg
   mov ss, ax
   mov ax, mem
   mov sp, ss_offs      
    
   IRET
RESIDENT_INTER ENDP   
LAST_BYTE: 





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


VERIFY_LOADING PROC        
   mov AH, 35h
   mov AL, 1Ch              ;Номер прерывания
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


; READ_TAIL PROC NEAR
     ; mov al, es:[81h+1]     ; es на psp
     ; cmp al, '/'
     ; jne err_tail
     ; mov al, es:[81h+2]
     ; cmp al, 'u'
     ; jne err_tail
     ; mov al, es:[81h+3]
     ; cmp al, 'n'
     ; jne err_tail
	 ; mov bool_var, 1
     ; jmp end_read
; err_tail:
	 ; mov bool_var, -1
; end_read:
     ; ret 	 
; READ_TAIL ENDP


DO_RESIDENT PROC	
    mov ax, SEGMENT_
	mov es, ax
	 ; call READ_TAIL
	 ; cmp bool_var, -1
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
	 mov AL, 1Ch
	 int 21h	 
	 mov si, offset KEEP_IP
	 sub si, offset RESIDENT_INTER
	 mov dx, es:[bx+si]
	 mov ax, es:[bx+si+2]
	 CLI
	 mov ds, ax
	 mov AH, 25H
	 mov AL, 1Ch
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














  
