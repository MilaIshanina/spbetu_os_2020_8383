TESTPC	SEGMENT
ASSUME	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG	100H
START:	JMP BEGIN

; Данные
UN_ADDRESS	db	'Unavailable memory segment address:     ',0dh,0ah,'$'
EN_ADDRESS	db	'Environment segment address:     ',0dh,0ah,'$'
COMMAND_TAIL		db	'Command line tail:',0dh,0ah,'$'
EN_CONTENTS	db	'Environment area contents: ','$'
MODULE_PATH		db	'Module load path: ','$'
ENDL			db	0dh,0ah,'$'

SEPARATION		db	'----------------------------------------',0dh,0ah,'$'


TETR_TO_HEX	PROC	near
		and	al,0fh
		cmp	al,09
		jbe	NEXT
		add	al,07
NEXT:		
		add	al,30h
		ret
TETR_TO_HEX	ENDP
;----------------------------------------
BYTE_TO_HEX	PROC near
		push cx
		mov	ah,al
		call TETR_TO_HEX
		xchg al,ah
		mov	cl,4
		shr	al,cl
		call TETR_TO_HEX 
		pop	cx 
		ret
BYTE_TO_HEX	ENDP
;---------------------------------------
WRD_TO_HEX	PROC	near
		push bx
		mov	bh,ah
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
WRD_TO_HEX	ENDP
;----------------------------

BEGIN:

;Сегм. адрес недоступной памяти

	push ax
	mov ax,es:[2]
	lea	di,UN_ADDRESS
	add di,39
	call WRD_TO_HEX
	pop	ax


;Сегм. адрес передаваемой среды

	push ax
	mov ax,es:[2Ch]
	lea	di,EN_ADDRESS
	add di,32
	call WRD_TO_HEX
	pop	ax

;Вывод на экран

lea dx, SEPARATION  
	mov	ah,09h
	int	21h
lea	dx,ENDL
	mov	ah,09h
	int	21h
	
	lea	dx,UN_ADDRESS  
	mov	ah,09h
	int	21h
		
	lea	dx,ENDL
	mov	ah,09h
	int	21h
	
	lea dx, SEPARATION  
	mov	ah,09h
	int	21h
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h
	
	lea	dx,EN_ADDRESS
	mov	ah,09h
	int	21h 
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h
	
	lea dx, SEPARATION  
	mov	ah,09h
	int	21h
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h

;Хвост командной строки в символьном виде

	lea dx, COMMAND_TAIL  
	mov	ah,09h
	int	21h

	push ax
	push cx
    xor	ax, ax		
    mov al, es:[80h]	
    add al, 81h			
    mov si, ax
    push es:[si]
    mov byte ptr es:[si+1], '$'		
    push ds				
    mov cx, es			
    mov ds, cx			
    mov dx, 81h
	mov	ah,09h			
	int	21h
   	pop ds
    pop es:[si]
    pop	cx
    pop	ax

    lea	dx,ENDL
	mov	ah,09h
	int	21h
	
	lea dx, SEPARATION  
	mov	ah,09h
	int	21h
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h

; Содержимое области среды в символьном виде

	lea	dx,EN_CONTENTS
	mov	ah,09h
	int	21h
   
	push es 
	mov	es,es:[2ch]			
	push ax
	push bx
	mov	bx,1
	push cx
	mov	si,0

ONE:	
	lea	dx,ENDL
	mov	ah,09h
	int	21h
	mov	ax,si 			

TWO:	
	cmp byte ptr es:[si], 0	
	je NEXT_ELEM		
	inc	si 			; Увеличиваем на 1
	jmp TWO

NEXT_ELEM:	
	push es:[si] 		
	mov	byte ptr es:[si], '$'
	push ds 
	mov	cx,es 
	mov	ds,cx
	mov	dx,ax

	mov	ah,09h
	int	21h 

	pop	ds 
	pop	es:[si] 
	cmp	bx,0 			
	jz 	LAST 			
	inc	si 			
	cmp byte ptr es:[si], 01h 	
    jne ONE
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h

; Путь загружаемого модуля
lea dx, SEPARATION  
	mov	ah,09h
	int	21h
	
	lea	dx,ENDL
	mov	ah,09h
	int	21h

    lea	dx,MODULE_PATH
	mov	ah,09h
	int	21h 

    mov	bx,0
    add si,2 			
    jmp ONE

LAST:	
	lea	dx,ENDL
	mov	ah,09h
	int	21h 

	pop	cx 
	pop	bx 
	pop	ax 
	pop	es

; выход в DOS
	xor	al,al
	mov ah, 01h
	int	21h
	mov ah, 04Ch
	int 21h
	ret
TESTPC	ENDS
END 	START
