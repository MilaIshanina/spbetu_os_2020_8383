CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK, ES:NOTHING


ROUT PROC FAR
    jmp START_ROUT
	INTER_NUMB db 'Interruptions :  0000'
	INTER_ID dw 7373h
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_PSP dw 0

START_ROUT:        
    push ax
    push bx
    push ds
    push dx
    push si
    push cx
    push es
    mov ax, seg INTER_NUMB
    mov ds, ax
    call getCurs
    push dx
    call setCurs
    mov ax, seg INTER_NUMB
    push ds
    mov ds, ax
    mov si, offset INTER_NUMB
    add si, 20
    mov cx, 4

COUNT_INTER_LOOP:
    mov ah, [si]
    inc ah
    mov [si], ah
    cmp ah, ':'
    jne END_LOOP
    mov ah, '0'
    mov [si], ah
    dec si
    loop COUNT_INTER_LOOP

END_LOOP:
    pop ds
    push es
    push bp
    mov ax, seg INTER_NUMB   
    mov es, ax
    mov bp, offset INTER_NUMB

    mov ah, 13h             
    mov al, 1h              
    mov bl, 5h              
    mov cx, 21              
    mov bh, 0               
    int 10h             
    pop bp              
    pop es              

    pop dx              
    mov ah, 02h             
    mov bh, 0h              
    int 10h             

    pop es
    pop cx
    pop si
    pop dx
    pop ds
    pop bx
    pop ax

    mov al, 20h
    out 20h, al
    IRET
ROUT ENDP
ROUT_END:

getCurs proc
    mov ah, 03h
    mov bh, 0
    int 10h 
    ret
getCurs ENDP

setCurs proc
    mov ah, 02h         
    mov bh, 00h           
    mov dl, 25h
    mov dh, 18h
    int 10h 
    ret
setCurs ENDP

START_OR_STOP_INTER PROC
    push ax
    push bx
    push si
    push es
	mov ax, KEEP_PSP
	mov es, ax
	cmp byte ptr es:[82h], '/'
	jne IS_LOAD
	cmp byte ptr es:[83h], 'u'
	jne IS_LOAD
	cmp byte ptr es:[84h], 'n'
    jne IS_LOAD
    mov IS_UN_FLAG, 1
    
IS_LOAD:
    mov ah, 35h
    mov al, 1Ch
    int 21h
    mov si, offset INTER_ID 
    sub si, offset ROUT
    mov ax, es:[bx+si]
    cmp ax, 7373h
    jne NOT_LOAD
    cmp IS_UN_FLAG, 1
    jne LOAD_AGAIN
    call STOP_INTER
    jmp END_SS

LOAD_AGAIN:
    mov dx, offset TRY_LOAD_AGAIN
    call PRINT_STRING
    jmp END_SS

NOT_LOAD:
    cmp IS_UN_FLAG, 1
    jne BEGIN_ROUT
    mov dx, offset TRY_TO_STOP
    call PRINT_STRING
    jmp END_SS

BEGIN_ROUT:
    call LOAD_INTER

END_SS:

    pop es
    pop si
    pop bx
    pop ax
    ret
START_OR_STOP_INTER ENDP

LOAD_INTER PROC
    push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov KEEP_CS, es
	mov KEEP_IP, bx
	push ds
	mov dx, offset ROUT
	mov ax, SEG ROUT	
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	mov dx, offset ROUT_END
	add dx, 10Fh
	mov cl, 4h
	shr dx, cl
	inc dx
	xor ax, ax
	mov ah, 31h
	int 21h
	
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_INTER ENDP

STOP_INTER PROC
    CLI
 	push ax
 	push bx
 	push dx
 	push ds
 	push es
 	push si
	
	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov si, offset KEEP_IP
	sub si, offset ROUT
	mov dx, es:[bx + si]
	mov ax, es:[bx + si + 2]
	push ds
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	mov ax, es:[bx + si + 4]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	mov ah, 49h
 	int 21h
	
	pop si
 	pop es
 	pop ds
 	pop dx
 	pop bx
 	pop ax
 	STI
	ret
STOP_INTER ENDP

PRINT_STRING PROC near
    push AX
    mov ah, 09h
	int 21h
    pop AX
    ret
PRINT_STRING ENDP

MAIN PROC
    xor ax, ax
    mov ax, DATA
    mov ds, ax
    mov KEEP_PSP, es
    call START_OR_STOP_INTER
    xor al, al
	mov ah, 4Ch
	int 21h
MAIN ENDP

CODE ENDS

ASTACK SEGMENT STACK
    dw 128 DUP(0)
ASTACK ENDS

DATA SEGMENT
    IS_UN_FLAG db 0
    INTER_LOAD_FLAG db 0
    TRY_TO_STOP db "Trying to stop not loaded interruption$"
    TRY_LOAD_AGAIN db "Trying to load interruption again$"
DATA ENDS
END MAIN