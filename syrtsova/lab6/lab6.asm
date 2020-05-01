CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK

TETR_TO_HEX PROC NEAR
		and 	al,0Fh
		cmp 	al,09
		jbe 	NEXT
		add 	al,07
NEXT: 	add 	al,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR		
		push 	cx
		mov 	ah,al
		call 	TETR_TO_HEX
		xchg 	al,ah
		mov 	cl,4
		shr 	al,cl
		call 	TETR_TO_HEX 	
		pop 	cx 				
		ret	
BYTE_TO_HEX ENDP

PRINT PROC NEAR			
		push 	ax	
		mov 	ah, 09h
		int 	21h
		pop 	ax
		ret
PRINT ENDP

ERROR_PROCESSING PROC NEAR
		cmp 	ax,7
		mov 	dx,offset error1_7
		je 		write_massage
		cmp 	ax,8
		mov 	dx,offset error1_8
		je 		write_massage
		cmp 	ax,9
		mov 	dx,offset error1_9
		je 		write_massage
		
	write_massage:
		call	 PRINT
		ret
ERROR_PROCESSING ENDP

CLEAR_MEMORY PROC NEAR
		mov 	ax,ASTACK 
		mov 	bx,es
		sub 	ax,bx 
		add 	ax,10h 
		mov 	bx,ax
		mov 	ah,4Ah
		int 	21h
		jnc 	end_clear
	
		call 	ERROR_PROCESSING
	
	end_clear:
		ret
CLEAR_MEMORY ENDP

CREATION_PARAMETER_BLOCK PROC NEAR
		mov  	ax, es:[2Ch]
		mov 	parameter_block, ax
		mov 	parameter_block+2, es 
		mov 	parameter_block+4, 80h 
		ret
CREATION_PARAMETER_BLOCK ENDP

ERR_PROCESSING PROC NEAR
		cmp 	ax,1
		mov 	dx,offset error2_1
		je 		write_message2
		cmp 	ax,2
		mov 	dx,offset error2_2
		je 		write_message2
		cmp 	ax,5
		mov 	dx,offset error2_5
		je 		write_message2
		cmp 	ax,8
		mov 	dx,offset error2_8
		je 		write_message2
		cmp 	ax,10
		mov 	dx,offset error2_10
		je 		write_message2
		cmp 	ax,11
		mov 	dx,offset error2_11
		
	write_message2:
		call 	PRINT
		ret
ERR_PROCESSING ENDP

COMPLETION_PROCESSING PROC NEAR
		mov 	dx, offset endl
		call 	PRINT
		cmp 	ah,0
		je 		normal
		cmp 	ah,1
		mov 	dx,offset end1
		je 		write_message3
		cmp 	ah,2
		mov 	dx,offset end2
		je 		write_message3
		cmp 	ah,3
		mov 	dx,offset end3
	normal:
		mov 	dx,offset  end0
		call	PRINT
		mov 	dx,offset output_code
		call 	PRINT
		call 	BYTE_TO_HEX
		push 	ax
		mov 	ah,02h
		mov 	dl,al
		int 	21h
		pop 	ax
		xchg 	ah,al
		mov 	ah,02h
		mov 	dl,al
		int 	21h
		jmp 	exit
	write_message3:
		call 	PRINT
	exit:
		ret
COMPLETION_PROCESSING ENDP

BASE_PROCESS PROC NEAR
		mov 	es,es:[2ch]
		mov 	si,0

	m1:
		mov 	dl,es:[si]
		cmp 	dl,0
		je 		m2
		inc 	si
		jmp 	m1
		
	m2:
		inc 	si
		mov 	dl,es:[si]
		cmp 	dl,0
		jne 	m1
		add 	si,3
		lea 	di,path
		
	m3:
		mov 	dl, es:[si]
		cmp 	dl,0
		je 		m4
		mov 	[di],dl
		inc 	di
		inc 	si
		jmp 	m3
		
	m4:
		sub 	di,8
		
		mov 	[di], byte ptr 'l'	
		mov 	[di+1], byte ptr 'a'
		mov 	[di+2], byte ptr 'b'
		mov 	[di+3], byte ptr '2'
		mov 	[di+4], byte ptr '.'
		mov 	[di+5], byte ptr 'c'
		mov 	[di+6], byte ptr 'o'
		mov 	[di+7], byte ptr 'm'
		mov 	dx,offset path 
		
		push 	ds
		pop 	es
		mov 	bx,offset parameter_block

		mov 	keep_sp, SP
		mov 	keep_ss, SS
	
		mov 	ax,4b00h
		int 	21h
		jnc 	success
	
		push 	ax
		mov 	ax,DATA
		mov 	ds,ax
		pop 	ax
		mov 	ss,keep_ss
		mov 	sp,keep_sp
	
	error:
		call 	ERR_PROCESSING
		ret
		
	success:
		mov ax,4d00h
		int 21h

		call	COMPLETION_PROCESSING
		ret
BASE_PROCESS ENDP

MAIN PROC far
		mov 	ax,data
		mov 	ds,ax
	
		call 	CLEAR_MEMORY
		call 	CREATION_PARAMETER_BLOCK
		call 	BASE_PROCESS
	
		xor 	al,al
		mov 	ah,4Ch
		int 	21h

MAIN ENDP
CODE ENDS

DATA SEGMENT
	parameter_block dw ? ;сегментный адрес среды
					dd ? ;сегмент и смещение командной строки
					dd ? ;сегмент и смещение первого FCB
					dd ? ;сегмент и смещение второго FCB

	error1_7    	db 'Memory control block destroyed', 10, 13, '$'
	error1_8		db 'Not enough memory to perform the function', 10, 13, '$'
	error1_9		db 'Wrong memory address', 10, 13, '$'
		

	error2_1 		db 'Number of function is incorrect', 10, 13, '$'
	error2_2		db 'File not found', 10, 13, '$'
	error2_5		db 'Disk error', 10, 13, '$'
	error2_8		db 'Insufficient memory', 10, 13, '$'
	error2_10		db 'Incorrect environment string', 10, 13, '$'
	error2_11		db 'Wrong format', 10, 13, '$'

	end0			db 'Normal completion', 10, 13, '$'
	end1			db 'Completion by Ctrl-Break', 10, 13, '$'
	end2			db 'Completion by device error', 10, 13, '$'
	end3			db 'Completion by function 31h', 10, 13, '$'

	endl 			db ' ', 10, 13, '$'

	output_code		db 'End code: $'
	
	path  			db 20h dup (0)

	keep_ss 		dw 0
	keep_sp 		dw 0
DATA ENDS

ASTACK SEGMENT STACK
	dw 100 dup (?) 
ASTACK ENDS
END MAIN