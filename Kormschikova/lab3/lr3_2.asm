LR SEGMENT
         ASSUME  CS:LR, DS:LR, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN

;DATA
 
	AV_MEM db 'Available memory: $' 
	BYTES db ' bytes $'
	BTEND db ' bytes. End: $'
	
 	NEW_LINE db 0DH, 0AH, '$'
	EX_MEM db 0DH, 0AH,'Extended memory: $'
	KB db ' KBytes ', 0DH, 0AH,  '$'
	MCB db 0DH, 0AH, 'MCB $'
	FRA db 0DH, 0AH, 'Free area  $'
	OSXMS db 0DH, 0AH,'OS XMS UMB  $'
	TOPMEM db 0DH, 0AH,'Top driver memory  $'
	MSD db 0DH, 0AH,'MS DOS  $'
	UMB_block db 0DH, 0AH,'Control block 386MAX UMB  $'
	UMB_blocked db 0DH, 0AH,'Blocked 386MAX  $'
	UMB_belongs db 0DH, 0AH,'Belongs 386MAX UMB  $'
	SIZE__ db  0DH, 0AH, 'Size: $'
	
 ;-----------------------------------------------------
 
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
 ; байт в AL переводится в два символа в шестн. числа в AX
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

PRINT_DEC PROC near
 	push ax
	push bx
	push cx
	push dx
	
	xor cx, cx
	mov bx, 10
	
looop:
	div bx
	push dx
	xor dx, dx
	inc cx
	cmp ax, 00h
	jne looop
	
	mov ah, 02h
	
print:
	pop dx
	or dl, 30h
	int 21h 
	loop print
	
	pop dx
	pop cx
	pop bx
	pop ax
 	ret
	
PRINT_DEC ENDP
 

PRINT_LINE PROC near
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
PRINT_LINE ENDP 


	
PRINT_SYMBOL PROC  near
	push ax
	mov ah, 02h 
	int 21h
	pop ax
	ret 
PRINT_SYMBOL    ENDP

PRINT_HEX PROC near
	
	push ax
	push ax
	mov al, ah 
	call BYTE_TO_HEX
	mov dl, ah
	call PRINT_SYMBOL
	mov dl, al
	call PRINT_SYMBOL
	pop ax
	call BYTE_TO_HEX
	mov dl, ah
	call PRINT_SYMBOL
	mov dl, al
	call PRINT_SYMBOL
	pop ax
	ret
PRINT_HEX ENDP


BEGIN:
	
;AVAILABLE MEM
	mov dx, offset AV_MEM
	call PRINT_LINE
	mov ah, 4Ah
	mov bx, 0ffffh
	int 21h 
	mov ax, bx
	mov bx, 10h
	mul bx
	call PRINT_DEC
	mov dx, offset BYTES
	call PRINT_LINE
	
;FREE MEM 
	mov ah, 4Ah 
	mov bx, offset LREND
	int 21h

;EXTENDED MEM
	mov dx, offset EX_MEM
	call PRINT_LINE
	
	mov al, 30h
	out 70h, al
	in al, 71h
	mov bl, al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov bh, al
	
	mov ax, bx
	xor dx, dx
	call PRINT_DEC
	mov dx, offset KB
	call PRINT_LINE
	
;MEMORY CONTROL BLOCK

	mov ah, 52h
	int 21h
	
	mov ax, es:[bx-2]
	mov es, ax
	xor cx, cx
listMCB:
	
	inc cx
	mov dx, offset MCB
	call PRINT_LINE
	mov ax, cx
	xor dx, dx
	call PRINT_DEC
	mov ax, es:[01h]
	
	cmp ax, 00h
	je FREE_AREA
	cmp ax, 06h
	je OS_XMS_UMB
	cmp ax, 07h
	je TOP_DRIVER_MEMORY
	cmp ax, 08h
	je MS_DOS
	cmp ax, 0FFFAh
	je UMB_CONTROL
	cmp ax, 0FFFDh
	je UMB_BLCKED
	cmp ax, 0FFFEh
	je UMB_BELNGS
	
	mov dx, offset NEW_LINE
	call PRINT_LINE
	call PRINT_HEX
	jmp SIZE_
	
FREE_AREA:
	mov dx, offset FRA
	jmp PRINT_OWNER	
	
OS_XMS_UMB:
	mov dx, offset OSXMS
	jmp PRINT_OWNER	
	
TOP_DRIVER_MEMORY:
	mov dx, offset TOPMEM
	jmp PRINT_OWNER	
	
MS_DOS:
	mov dx, offset MSD
	jmp PRINT_OWNER	

UMB_CONTROL:
	mov dx, offset UMB_block
	jmp PRINT_OWNER	

UMB_BLCKED:
	mov dx, offset UMB_blocked
	jmp PRINT_OWNER	

UMB_BELNGS:
	mov dx, offset UMB_belongs
	jmp PRINT_OWNER	
	
	
PRINT_OWNER:
	call PRINT_LINE
	
SIZE_: 
	mov dx, offset SIZE__
	call PRINT_LINE
	mov ax, es:[3h]
	mov bx, 10h
	mul bx
	call PRINT_DEC
	mov dx, offset BTEND
	call PRINT_LINE
	
	mov ah, 02h
	xor si, si 
	push cx
	mov cx, 8
	
LAST_LOOP:
	mov dl, es:[si+8h]
	int 21h
	inc si
	loop LAST_LOOP
	pop cx
	
	mov ax, es:[00h]
	cmp al, 5Ah
	je EXIT
	
	mov ax, es:[03h]
	mov bx, es
	add bx, ax
	inc bx
	mov es, bx
	jmp listMCB
	
;exit to dos
EXIT:
	xor AL,AL
	mov AH,4Ch
	int 21H
LREND:
LR     ENDS
END START