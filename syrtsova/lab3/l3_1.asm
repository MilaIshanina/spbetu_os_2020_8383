testpc segment
		assume cs:testpc, ds: testpc, es:nothing, ss:nothing
		org 100h
start: jmp begin

;данные

AVAILABLE_MEM 		db 'Available memory (B):        ', 10, 13, '$'
EXTENDED_MEM 		db 'Extended memory (KB):        ', 10, 13, '$'
TABLE_TITLE 		db '| MCB Type | PSP Address | Size | SC/SD |', 10, 13, '$'
TABLE_MCB_DATA  	db '                                                                    ', 10, 13, '$'

; процедуры

PRINT PROC NEAR
		push ax
		mov 	ah, 09h
		int		21h
		pop ax
		ret
PRINT ENDP

TETR_TO_HEX PROC NEAR

	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	
	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX 
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  
	pop CX
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC NEAR
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
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
end_l:	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

WRD_TO_DEC PROC NEAR
	push CX
	push DX
	mov CX,10
loop_b: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_b
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
endl:	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

GET_AVAILABLE_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si
	xor ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset AVAILABLE_MEM
	add si, 27
	call WRD_TO_DEC
	mov dx, offset AVAILABLE_MEM
	call PRINT
	pop si
	pop dx
	pop bx
	pop ax
	ret
GET_AVAILABLE_MEMORY ENDP

GET_EXTENDED_MEMORY PROC NEAR
	push ax
	push bx
	push dx
	push si
	xor dx, dx
	mov al, 30h
    out 70h, al
    in al, 71h 
    mov bl, al 
    mov al, 31h  
    out 70h, al
    in al, 71h
	mov ah, al
	mov al, bl
	mov si, offset EXTENDED_MEM
	add si, 26
	call WRD_TO_DEC
	mov dx, offset EXTENDED_MEM
	call PRINT
	pop si
	pop dx
	pop bx
	pop ax
	ret
GET_EXTENDED_MEMORY ENDP

GET_MCB_TYPE PROC NEAR
	push ax
	push di
	mov di, offset TABLE_MCB_DATA
	add di, 5
	xor ah, ah
	mov al, es:[00h]
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	pop di
	pop ax
	ret
GET_MCB_TYPE ENDP

GET_PSP_ADDRESS PROC NEAR
	push ax
	push di
	mov di, offset TABLE_MCB_DATA
	mov ax, es:[01h]
	add di, 19
	call WRD_TO_HEX
	pop di
	pop ax
	ret
GET_PSP_ADDRESS ENDP

GET_MCB_SIZE PROC NEAR
	push ax
	push bx
	push di
	push si
	mov di, offset TABLE_MCB_DATA
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	add di, 29
	mov si, di
	call WRD_TO_DEC
	pop si
	pop di
	pop bx
	pop ax
	ret
GET_MCB_SIZE ENDP

GET_SC_SD PROC NEAR
	push bx
	push dx
	push di
	mov di, offset TABLE_MCB_DATA
	add di, 33
    mov bx, 0h
	GET_8_BYTES:
        mov dl, es:[bx + 8]
		mov [di], dl
		inc di
		inc bx
		cmp bx, 8h
	jne GET_8_BYTES
	pop di
	pop dx
	pop	bx
	ret
GET_SC_SD ENDP

GET_MCB_DATA PROC NEAR
	mov ah, 52h
	int 21h
	sub bx, 2h
	mov es, es:[bx]
FOR_EACH_MCB:
		call GET_MCB_TYPE
		call GET_PSP_ADDRESS
		call GET_MCB_SIZE
		call GET_SC_SD
		mov ax, es:[03h]
		mov bl, es:[00h]
		mov dx, offset TABLE_MCB_DATA
		call PRINT
		mov cx, es
		add ax, cx
		inc ax
		mov es, ax
		cmp bl, 4Dh
		je FOR_EACH_MCB
	ret
GET_MCB_DATA ENDP

begin:
    call GET_AVAILABLE_MEMORY
	call GET_EXTENDED_MEMORY
	mov dx, offset TABLE_TITLE
	call PRINT
	call GET_MCB_DATA	
	xor al, al
	mov ah, 4ch
	int 21h
testpc ends
end start