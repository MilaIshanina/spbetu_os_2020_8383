TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN
	AMOUNT_MEM db 13, 10, "Amount of available memory:         $"
	EX_ME db  13, 10, "Extended memory:           $"
	OUT_STR db 13, 10, "             $"
	NUM db 13, 10, "           $"
	ENDL db 13, 10, '$'	
	ST_1 db 13, 10, "free area$"
	ST_2 db "OS XMS UMB$"
	ST_3 db "driver's top memory$"
	ST_4 db "MS DOS$"
	ST_5 db "control block 386MAX UMB$"
	ST_6 db "blocked 386MAX$"
	ST_7 db "386MAX UMB$"
	
	AREA_BELONGS db 13, 10, "area belongs to $"
	SIZE_OF_AREA db 13, 10, "size of area: $"
	SIZE DB "           $"
	
	FREE_OK db 13, 10, "FREE OK$"
	FREE_NOT_OK db 13, 10, "FREE NOT OK$"
	
	ALLOC_OK db 13, 10, "ALLOCATE OK$"
	ALLOC_NOT_OK db 13, 10, "ALLOCATE NOT OK"

;-----------------------------------------------------

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;----------------------------------------------------

BYTE_TO_HEX PROC near
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
;-----------------------------------------------------

WRD_TO_HEX PROC near

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
;-----------------------------------------------

AVAIL_MEMORY PROC near
	push ax
	push bx
	push dx
		
	mov di, offset AMOUNT_MEM
	add di, 33
	mov ah, 4Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, bx
	mov bx, 10h
	mul bx
	call WRD_TO_HEX 
	mov dx, offset AMOUNT_MEM
	call PRINT
		
	pop dx
	pop bx
	pop ax
	ret
AVAIL_MEMORY ENDP
;-----------------------------------------------

LENGTH_OF_EXTENDED_MEMPRY PROC near

PUSH AX
PUSH BX
PUSH DX

	xor ax, ax
	mov AL,30h 
 
	out 70h,AL
	in AL,71h 
	mov BL,AL 
	mov AL,31h 
	out 70h,AL
	in AL,71h

	mov bh, ah
	mov ah, al
	mov al, bh


	mov di, offset EX_ME
	add di, 22
	call WRD_TO_HEX 
	mov dx, offset EX_ME
	call PRINT


POP DX
POP BX
POP AX


	RET
LENGTH_OF_EXTENDED_MEMPRY ENDP

;-----------------------------------------------

OUT_MEMORY_BLOCKS PROC near

push ax
push bx
push dx

	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]	
	mov es, ax
	xor cx, cx
NEXT_1:
	
	inc cx
	mov ax, cx
	
	mov di, offset NUM
	add di, 8
	call WRD_TO_HEX 
	mov dx, offset NUM
	call PRINT
	
	push cx
	xor ax, ax
	mov al, es:[0h]
	push ax
	mov ax, es:[1h]
	
	mov dx, offset AREA_BELONGS
	
	cmp ax, 0h
	je M_ST_1
	cmp ax, 6h
	je M_ST_2
	cmp ax, 7h
	je M_ST_3
	cmp ax, 8h
	je M_ST_4
	cmp ax, 0FFFAh
	je M_ST_5
	cmp ax, 0FFFDh
	je M_ST_6
	cmp ax, 0FFFEh
	je M_ST_7
	
	mov di, offset OUT_STR
	add di, 5
	call WRD_TO_HEX 
	mov dx, offset OUT_STR
	call PRINT
	jmp M_END
	

M_ST_1:
	mov dx, offset ST_1
	jmp M_PR;
M_ST_2:
	call PRINT
	mov dx, offset ST_2
	jmp M_PR;
M_ST_3:
	call PRINT
	mov dx, offset ST_3
	jmp M_PR;
M_ST_4:
	call PRINT
	mov dx, offset ST_4
	jmp M_PR;
M_ST_5:
	call PRINT
	mov dx, offset ST_5
	jmp M_PR;
M_ST_6:
	call PRINT
	mov dx, offset ST_6
	jmp M_PR;
M_ST_7:
	call PRINT
	mov dx, offset ST_7
	jmp M_PR;
	
M_PR:
	call PRINT
	
M_END:
	mov ax, es:[3h]
	mov bx, 10h
	mul bx
	
	mov dx, offset SIZE_OF_AREA
	call PRINT
	
	mov di, offset SIZE
	add di, 5
	call WRD_TO_HEX 
	mov dx, offset SIZE
	call PRINT
	
	
	mov cx, 8
	xor si, si
	
M_LOOP:
	mov dl, es:[si+8h]
	mov ah, 02h
	int 21h
	inc si
	loop M_LOOP
	
	mov ax, es:[3h]
	mov bx, es
	add bx, ax
	inc bx
	mov es, bx
	pop ax
	pop cx
	cmp al, 5Ah
	je END_P
	jmp NEXT_1

END_P:	


pop dx
pop bx
pop ax

	ret
OUT_MEMORY_BLOCKS ENDP

;-----------------------------------------------

FREE_MEM PROC near

push ax
push bx
push cx

mov bx, offset END_PROG
add bx, 10Fh
shr BX, 4
mov ah, 4Ah
int 21h
jnc OK
mov dx, offset FREE_NOT_OK
jmp END_F

OK:
	mov dx, offset FREE_OK


END_F:
	call PRINT

pop cx
pop bx
pop ax

ret
FREE_MEM ENDP
;-----------------------------------------------

ALLOCATE_MEM PROC near
push ax
push bx
push dx

mov bx, 1000h
mov ah, 48h
int 21h
jnc AL_OK
mov dx, offset ALLOC_NOT_OK
jmp END_A


AL_OK:
	mov dx, offset ALLOC_OK
END_A:
	
	call PRINT

pop dx
pop bx
pop ax
ret
ALLOCATE_MEM ENDP
;-----------------------------------------------

BEGIN:

	call AVAIL_MEMORY
		call ALLOCATE_MEM
		call FREE_MEM
	call LENGTH_OF_EXTENDED_MEMPRY
	call OUT_MEMORY_BLOCKS
	
	xor AL, AL
	mov AH, 4Ch
	int 21h
	
	PROG_FREE:
		DW 128 dup(0)
	END_PROG:
TESTPC ENDS
	END START