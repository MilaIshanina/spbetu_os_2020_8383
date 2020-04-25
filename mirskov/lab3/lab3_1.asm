TESTPC    SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN

ENTER_STRING db 0DH,0AH,'$'
AVALIBLE_STRING db 'Avalible memory ','$'
EXTENDED_STRING db 'Extended memory ','$'
BYTES db ' bytes','$'
KILOBYTES db ' kilobytes', '$'
FREE_SUCCES_STR db 'FREE SUCCES', '$'
FREE_BAD_STR db 'FREE NOT SUCCES', '$'
ALLOCATE_SUCCES_STR db 'ALLOCATE SUCCES', '$'
ALLOCATE_BAD_STR db 'ALLOCATE NOT SUCCES', '$'
OWNER_ADDRESS db 'OWNER ADDRESS ', '$'
SIZE_STR db 'SIZE ', '$'


;процедуры
;---------------------------------------------
NEW_LINE   PROC near
      push AX
      push DX

      mov dx, offset ENTER_STRING
      mov AH, 09h
      int 21h

      pop DX
      pop AX

      ret
NEW_LINE ENDP
;--------------------------------------------------
PRINT_STR    PROC near
	  push AX
	  mov AH, 09h
      int 21h
      pop ax
      ret
PRINT_STR ENDP
;--------------------------------------------------
PRINT_DX_AX_TO_DEC   PROC near
; перевод числа в регистре dx:ax в 10 с/c
      xor cx, cx
      mov bx, 10
    fill_stack:
      div bx
      push dx
      xor dx, dx
      inc cx
      test ax, ax
      jnz fill_stack

      mov ah, 02h
    print_stack:
      pop dx
      add dl, '0'
      int 21h
      loop print_stack

      ret
PRINT_DX_AX_TO_DEC   ENDP
;----------------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;---------------------------------------------------------
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
;-------------------------------------------
PRINT_BYTE   PROC near
	  call BYTE_TO_HEX
	  push AX
	  mov DL, AL
	  mov AH, 02h
	  int 21h
	  pop AX
	  mov DL, AH
	  mov AH, 02h
	  int 21h

	  ret
PRINT_BYTE ENDP
;-----------------------------------------------
PRINT_AVALIBLE   PROC  near
      mov dx, offset AVALIBLE_STRING
      call PRINT_STR

	  mov AH, 4AH
	  mov BX, 0FFFFH
	  int 21h
	  mov AX, 16
	  mul BX

      call PRINT_DX_AX_TO_DEC
      mov dx, offset BYTES
      call PRINT_STR
      call NEW_LINE

	  ret
PRINT_AVALIBLE ENDP
;--------------------------------------------------
PRINT_EXTENDED   PROC near
      mov dx, offset EXTENDED_STRING
      call PRINT_STR

      mov AL, 30h
      out 70h, AL
      in AL, 71h
      mov BL, AL
      mov AL, 31h
      out 70h, AL
      in AL, 71h
      mov AH, AL

      mov AL, BL
      xor DX, DX
      call PRINT_DX_AX_TO_DEC
      mov dx, offset KILOBYTES
      call PRINT_STR
      call NEW_LINE
      call NEW_LINE

      ret
PRINT_EXTENDED ENDP
;-------------------------------
PRINT_MCB   PROC near
      mov AH, 52h
      int 21h
      mov AX, ES:[BX-2]
      mov ES, AX
    MCB_BEGIN:
      mov AL, ES:[0]
      call PRINT_BYTE
      call NEW_LINE

      mov dx, offset OWNER_ADDRESS
      call PRINT_STR
      mov AL, ES:[2]
      call PRINT_BYTE
      mov AL, ES:[1]
      call PRINT_BYTE
      call NEW_LINE

      mov dx, offset SIZE_STR
      call PRINT_STR
      xor DX, DX
      mov AX, ES:[3]
      mov BX, 16
      mul BX
      call PRINT_DX_AX_TO_DEC
      call NEW_LINE

      mov AH, 02h
      mov BX, 8
    last_eight:
      mov DL, ES:[BX]
      int 21h
      inc BX
      cmp BX, 16
      jne last_eight
      call NEW_LINE
      call NEW_LINE

      mov AX, ES:[0]
      mov BX, ES:[3] 
      mov DX, ES
      add BX, DX
      inc BX
      mov ES, BX
      xor AH, AH
      cmp AX, 4Dh
      je MCB_BEGIN

      ret
PRINT_MCB ENDP
;--------------------------------------------
FREE_MEMORY   PROC near
	  push AX
	  push BX

	  mov BX, offset STACK_END
	  add BX, 10Fh
	  shr BX, 4
	  mov AH, 4AH
	  int 21h

	  jnc FREE_SUCCES
	  mov dx, offset FREE_BAD_STR
	  call PRINT_STR
	  jmp FREE_END

	FREE_SUCCES:
	  mov dx, offset FREE_SUCCES_STR
      call PRINT_STR

    FREE_END:
      call NEW_LINE
	  pop BX
	  pop AX
	  ret
FREE_MEMORY ENDP
;--------------------------------------------
ALLOCATE_MEMORY   PROC near
	  push AX
	  push BX
	  
	  mov BX, 1000h
	  mov AH, 48h
	  int 21h

	  jnc ALLOCATE_SUCCES
	  mov dx, offset ALLOCATE_BAD_STR
	  call PRINT_STR
	  jmp ALLOCATE_END

	ALLOCATE_SUCCES:
	  mov dx, offset ALLOCATE_SUCCES_STR
      call PRINT_STR

    ALLOCATE_END:
      call NEW_LINE
	  pop BX
	  pop AX

	  ret
ALLOCATE_MEMORY ENDP
;--------------------------------------------


BEGIN:
	  call PRINT_AVALIBLE
      call PRINT_EXTENDED
      ;call FREE_MEMORY
      ;call ALLOCATE_MEMORY
      call PRINT_MCB

; вход в DOS
      xor     AL,AL
      mov     AH,4Ch
      int     21H

      STACK_BEGIN:
    	  dw 128 dup(0)
      STACK_END:

TESTPC      ENDS
END     START     ;конец модуля, START - точка входа
