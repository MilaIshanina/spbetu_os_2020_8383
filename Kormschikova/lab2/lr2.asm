LR SEGMENT
         ASSUME  CS:LR, DS:LR, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN

;DATA
 
	LOCKED_MEM db 0DH, 0AH, 'Locked memory: $' 
	ENVIROMENT db 0DH, 0AH, 'Enviroment address: $'
	TAIL db 0DH, 0AH, 'Command line tail: $'
	NO_TAIL db 0DH, 0AH, 'No command line tail $'
	ENVIROMENT_C db 0DH, 0AH, 'Enviroment content:', 0DH, 0AH, '$'
	PATH db 0DH, 0AH, 'Path:  $'
	NL db 0DH, 0AH,'$'
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
	
;LOCKED MEMORY
	mov dx, offset LOCKED_MEM
	call PRINT_LINE
	mov ax, ds:[02h]
	call PRINT_HEX
	
;ENVIROMENT
	mov dx, offset ENVIROMENT
	call PRINT_LINE
	mov ax, ds:[2Ch]
	call PRINT_HEX
	
;TAIL
	mov cl, ds:[80h]
	cmp cl, 0
	je NTAIL	
	mov ch, 0
	mov di, 0
LOOOP:
	mov dl, ds:[81h+di]
	call PRINT_SYMBOL
	add di, 1
	loop LOOOP
	jmp ENDT
	
NTAIL:
	mov dx, offset NO_TAIL
	call PRINT_LINE
	
ENDT:
;Enviroment content
	mov dx, offset ENVIROMENT_C
	call PRINT_LINE
	mov bx, 2ch
	mov es, [bx]
	mov si, 0
	
EN_C:
	cmp BYTE PTR es:[si], 0h
	je NEXTT
	mov dl, es:[si]
	call PRINT_SYMBOL
	jmp PR

NEXTT:
	mov dx, offset NL
	call PRINT_LINE 
PR:
	add si, 1
	cmp WORD PTR es:[si], 0001h
	je PATH_S
	jmp  EN_C

PATH_S:
	mov dx, offset PATH
	call PRINT_LINE
	add si, 2
LOOOOP:
	cmp BYTE PTR es:[si], 00h
	je EXIT
	mov dl, es:[si]
	call PRINT_SYMBOL
	add si, 1
	jmp LOOOOP
	
;exit to dos
EXIT:
	xor AL,AL
	mov AH,4Ch
	int 21H
	
LR     ENDS
END START