TESTPC     SEGMENT
           ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   ORG 100H    ;обязательно!
START:     JMP MAIN


LEN_MSG_PSP  EQU 18
LEN_ENV_SEG EQU 28


MSG_SIZE_MEM db 13,10, "Size available memory (b): $" 
MSG_SIZE_ENV_MEM db 13,10, "Size extend memory (kb): $" 


MSG_NUM db 13,10,"Num: $"
MSG_PSP db 13,10,"PSP address:            $" 
MSG_SIZE db 13,10, "Size (b): $"
MSG_NAME_PROG db 13,10, "Name: $"

MSG_ENTER db 13,10, "-------------------------------$"
       

;-------------------------------

WRITE_STR PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE_STR ENDP
;-------------------------------
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
; байт в AL переводится в два символа шестн. числа в AX
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
WRD_TO_HEX   PROC  near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC   PROC  near
; перевод в 10с/с, SI - адрес поля младшей цифры
           push     CX
           push     DX
           xor      AH,AH
           xor      DX,DX
           mov      CX,10
loop_bd:   div      CX
           or       DL,30h
           mov      [SI],DL
		   dec		si
           xor      DX,DX
           cmp      AX,10
           jae      loop_bd
           cmp      AL,00h
           je       end_l
           or       AL,30h
           mov      [SI],AL
		   
end_l:     pop      DX
           pop      CX
           ret
BYTE_TO_DEC    ENDP
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
; Funct lab_3






PRINT_DEC_NUM PROC near
    xor cx, cx    ; количество цифр в cx.
    mov bx, 10    ; основ. в bx
step1:             ; число в ax  
    div bx
    push dx
	xor dx,dx
    inc cx
    test ax, ax
	;cmp ax, 0
    jnz step1
    
step2:
	pop dx
    add dl, '0'
	mov ah, 02h
	int 21h
    loop step2  
    ret
PRINT_DEC_NUM ENDP



PRINT_MEM PROC near
	push dx
	mov dx, offset MSG_SIZE_MEM
	call WRITE_STR
	mov ah,4ah
	mov bx,0ffffh
	int 21h
	mov ax, bx
	mov bx,10h
	mul bx
	call PRINT_DEC_NUM
	pop dx
    ret
	
PRINT_MEM ENDP


PRINT_EXETEN_MEM PROC near
	mov dx, offset MSG_SIZE_ENV_MEM
	call WRITE_STR
	mov al, 30h  ; запись адреса ячейки CMOS
	out 70h, al   
	in al, 71h   ; чтение младшего байта
	mov bl, al   ; размер расширенной памяти
	mov al, 31h  ; запись адреса ячейки CMOS
	out 70h, al
	in al, 71h   ; чтение старшего байта 
	mov bh, al
	mov ax, bx
	xor dx, dx
	call PRINT_DEC_NUM
	ret
PRINT_EXETEN_MEM ENDP


PRINT_MCB PROC near
	push AX
	push BX
	push CX
	push DX
	push ES
	push SI
	mov dx, offset MSG_ENTER
    call WRITE_STR
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]   ;first MCB
	mov es, ax
	mov di, 1

cycle_msb:
    
	mov dx, offset MSG_NUM
	call WRITE_STR
	mov ax, di
	mov dx, 0
	call PRINT_DEC_NUM
	
	mov ax, es:[01h]
	push di
	mov di, offset MSG_PSP
	add di, LEN_MSG_PSP
	call WRD_TO_HEX
	pop di
	mov dx, offset MSG_PSP
	call WRITE_STR
	
	mov dx, offset MSG_SIZE
	call WRITE_STR
	mov ax, es:[03h]
	mov bx,10h
	mul bx
	call PRINT_DEC_NUM
	
	mov dx, offset MSG_NAME_PROG
	call WRITE_STR
	mov si, 0
	mov cx, 8
	jcxz exit
cycle_name:
	mov dl, es:[si+08h]
	mov ah, 02h
	int 21h
    dec cx
	inc si
    cmp cx, 0
	jne cycle_name 
exit:	
if_end:
	mov al, es:[00h]
	cmp al, 5Ah
	je end_mcb
	mov ax, es:[03h]
	mov bx, es
	add bx, ax
	inc bx
	mov es, bx
	mov dx, offset MSG_ENTER
	call WRITE_STR
	inc di
    jmp cycle_msb
end_mcb:
	pop SI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PRINT_MCB ENDP


FREE_MEMORY PROC
	mov ax, offset end_prog
	mov bx,10h
	xor dx,dx
	div bx
	inc ax
	mov bx,ax    ;в параграфах
	mov al,0
	mov ah,4Ah
	int 21h
	ret
FREE_MEMORY ENDP


MAIN:
   call PRINT_MEM
   ;call FREE_MEMORY
   call PRINT_EXETEN_MEM
   call PRINT_MCB
   xor al, al
   mov AH,4Ch
   int 21H
   end_prog:
TESTPC ENDS
END START
