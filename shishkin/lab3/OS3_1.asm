TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
	AM_STR db 13, 10, "Amount of available memory:           $"
	EM_STR db 13, 10, "Extended memory size:          $"
	NUM_STR db 13, 10, "Number     $"
	NEW_LINE db 13, 10, "---------------------------------$"
	FREE_AREA_STR db 13, 10, "Free area$"
	OS_XMSUMP_STR db 13, 10, "Area belongs to the driver OS XMS UMB$"
	UPPER_MEMORY_STR db 13, 10, "Area is excluded upper driver memory$"
	MS_DOS_STR db 13, 10, "Area belongs to MS DOS$"
	BUSY_386MAX_STR db 13, 10, "Area is occupied by the control unit 386 MAX UMB$"
	BLOCK_386MAX_STR db 13, 10, "Area is blocked by 386 MAX$"
	BELONG_386MAX_STR db 13, 10, "Area belongs to the 386 MAX UMB$"
	PSP_MEMORY_OWNER_STR db 13, 10, "     $"
	AREA_SIZE_STR db 13, 10, "Area size:             $"

;-----------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ; в AL старшая цифра
	pop CX ;в AH - младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с.с. 16-ти разрядного числа
; в AX - число, в DI - адрес последнего символа
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
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с.с., SI - адрес поля младшей цифры
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
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;-----------------------------------------------
PRINT PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;----------------------------------------------
AVAILABLE_MEMORY PROC near
	push ax
	push bx
	push dx
		
	mov di, offset AM_STR
	add di, 33
	mov ah, 4Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, bx
	mov bx, 10h
	mul bx
	call WRD_TO_HEX 
	mov dx, offset AM_STR
	call PRINT
		
	pop dx
	pop bx
	pop ax
	ret
AVAILABLE_MEMORY ENDP
;----------------------------------------------
EXTENDED_MEMORY PROC near
	push ax
	push bx
	push dx

	mov di, offset EM_STR
	add di, 27
	mov al,30h
	out 70h, al
	in al, 71h
	mov bl, al
	mov al,31h
	out 70h, al
	in al, 71h
	mov bh, ah
	mov ah, al
	mov al, bh

	call WRD_TO_HEX
	mov dx, offset EM_STR
	call PRINT	

	pop dx
	pop bx
	pop ax
	ret
EXTENDED_MEMORY ENDP
;----------------------------------------------
MCB PROC near
	push ax
	push bx
	push cx
	push di
	push si

	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	xor cx, cx
	
	next_mcb:
		inc cx
		mov dx, offset NEW_LINE
		call PRINT
		mov si, offset NUM_STR 
		add si, 9
		mov ax, cx
		push cx
		call BYTE_TO_DEC 
		mov dx, offset NUM_STR
		call PRINT

		xor ax, ax
		mov al, es:[0h]
		push ax
		mov ax, es:[1h]
		
		cmp ax, 0h
		je if_free_area
		cmp ax, 6h
		je if_driver
		cmp ax, 7h
		je if_upper_memory
		cmp ax, 8h
		je if_msdos
		cmp ax, 0FFFAh
		je if_386max_umb
		cmp ax, 0FFFDh
		je if_block_386max
		cmp ax, 0FFFEh
		je if_belongs_386max

		xor dx, dx
		mov di, offset PSP_MEMORY_OWNER_STR 
		add di, 5
		call WRD_TO_HEX 
		mov dx, offset PSP_MEMORY_OWNER_STR 
		jmp end_of_01h		
		pop ax

	if_free_area:
		mov dx, offset FREE_AREA_STR
		jmp end_of_01h

	if_driver:
		mov dx, offset OS_XMSUMP_STR
		jmp end_of_01h

	if_upper_memory:
		mov dx, offset UPPER_MEMORY_STR  
		jmp end_of_01h

	if_msdos:
		mov dx, offset MS_DOS_STR 
		jmp end_of_01h

	if_386max_umb:
		mov dx, offset BUSY_386MAX_STR 
		jmp end_of_01h

	if_block_386max:
		mov dx, offset BLOCK_386MAX_STR 
		jmp end_of_01h
			
	if_belongs_386max:
		mov dx, offset BELONG_386MAX_STR 
		jmp end_of_01h

	end_of_01h:
		call PRINT
		mov di, offset AREA_SIZE_STR 
		add di, 16
		mov ax, es:[3h]
		mov bx, 10h
		mul bx
		call WRD_TO_HEX
		mov dx, offset AREA_SIZE_STR 
		call PRINT
		mov cx, 8
		xor si, si

	end_of_mcb:
		mov dl, es:[si+8h]
		mov ah, 02h
		int 21h
		inc si
		loop end_of_mcb

		mov ax, es:[3h]
		mov bx, es
		add bx, ax
		inc bx
		mov es, bx
		pop ax 
		pop cx
		cmp al, 5Ah
		je end_of_proc
		jmp next_mcb
	
	end_of_proc:
		pop si
		pop di	
		pop cx
		pop bx
		pop ax
	ret
MCB ENDP
;----------------------------------------------
BEGIN:

	call AVAILABLE_MEMORY 
	call EXTENDED_MEMORY 
	call MCB
	
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC ENDS
	END START