TESTPC SEGMENT
ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG 100H
START: JMP BEGIN

SYSTEM_VER db 13,10,"OS version: $"
FORM_SER db "  .  $" 
OEM db 13, 10, "Number OEM: $"
OEM_FORM db "      $"	
NUMBER db 13, 10, "Serial number: $"
NUM_FORM db "            $"
PC db "PC$"
PCXT db "PC/XT$"
A_T db "AT$"
PS2_30 db "PS2 model 30$"
PS2_50 db "PS2 model 50 or 60$"
PS2_80 db "PS2 model 80$"
PCJR db "PCjr$"
PCC db "PC convertible$"
PC_VER db "Version pc: $"
;--------------------------------------------------
WRITE PROC near
	push ax
	mov ah, 9h
	int 21h
	pop ax
	ret
WRITE ENDP
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
;-------------------------------

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
;-------------------------------

BEGIN:
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
	mov dx, offset PC_VER
	call WRITE
	cmp al, 0ffh
	je PC_TYPE
	cmp al, 0feh
	je XT_TYPE
	cmp al, 0fbh
	je XT_TYPE
	cmp al, 0fch
	je AT_TYPE
	cmp al, 0fah
	je PS2_30_TYPE
	cmp al, 0fch
	je PS2_5060_TYPE
	cmp al, 0f8h
	je PS2_80_TYPE
	cmp al, 0fdh
	je PCJR_TYPE
	cmp al, 0f9h
	je CON_TYPE
	
PC_TYPE:
	mov dx, offset PC
	call WRITE
	jmp FINISH
XT_TYPE:
	mov dx, offset PCXT
	call WRITE
	jmp FINISH
AT_TYPE:
	mov dx, offset A_T
	call WRITE
	jmp FINISH
PS2_30_TYPE:
	mov dx,offset PS2_30
	call WRITE
	jmp FINISH
PS2_5060_TYPE:
	mov dx, offset PS2_50
	call WRITE
	jmp FINISH
PS2_80_TYPE:
	mov dx, offset PS2_80
	call WRITE
	jmp FINISH
PCJR_TYPE:
	mov dx, offset PCJR
	call WRITE
	jmp FINISH
CON_TYPE:
	mov dx, offset PCC
	call WRITE
	jmp FINISH

FINISH:
;-----------------------------------
	mov ah, 30h
	int 21h
	push ax
	mov dx, offset SYSTEM_VER
	call WRITE
	mov si, offset FORM_SER
	inc si
	call BYTE_TO_DEC
	pop ax
    mov al, ah     
    add si, 3
	call BYTE_TO_DEC
	mov dx, offset FORM_SER
	call WRITE
	mov dx, offset OEM
	call WRITE
	mov si, offset OEM_FORM
	add si, 5
	mov al, bh                 
	call BYTE_TO_DEC
	mov dx, offset OEM_FORM
	call WRITE
	mov dx, offset NUMBER
    call WRITE
    mov di, offset NUM_FORM
	add di, 10
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset NUM_FORM
	call WRITE
	mov ax, 4c00h
	int 21h

	
TESTPC ENDS
END START 