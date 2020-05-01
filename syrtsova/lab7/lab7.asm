AStack SEGMENT  STACK
        dw 64 dup(?)			
AStack ENDS


CODE SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack


DATA SEGMENT
		error1_7     db 'Memory control block destroyed',13, 10,'$'
		error1_8     db 'Not enough memory to perform the function',13, 10,'$'
		error1_9     db 'Wrong memory address',13, 10,'$'
		error3_1	 db 'Error: Non-existent function', 13, 10, '$'   
		error3_2  	 db 'Error: File not found', 13, 10, '$'
		error3_3  	 db 'Error: Path not found', 13, 10, '$'
		error3_4  	 db 'Error: Too many opened files', 13, 10, '$'
		error3_5  	 db 'Error: No access', 13, 10, '$'					
		error3_8  	 db 'Error: Not enough memory', 13, 10, '$'					
		error3_10 	 db 'Error: Incorrect environment', 13, 10, '$'
		error2_2	 db 'Error: File not found', 13, 10, '$'
		error2_3 	 db 'Error: Path not found', 13, 10, '$'
	
		str_overlay1		db 'OVERLAY1.ovl', 0
		str_overlay2 		db 'OVERLAY2.ovl', 0
		DTA 				db 43 dup (0), '$'
		OVERLAY_PATH 		db 100h	dup (0), '$'
		OVERLAY_ADDR 		dd 0
		KEEP_PSP 			dw 0
		OVERLAY_ADDRESS 	dw 0
DATA 	ENDS


PRINT PROC NEAR 
		push	ax
		mov 	ah, 09h
		int 	21h
		pop 	ax
		ret
PRINT ENDP

ERROR_PROCESSING1 PROC NEAR
		cmp 	ax,7
		mov 	dx,offset error1_7
		je 		write_message1
		cmp 	ax,8
		mov 	dx,offset error1_8
		je 		write_message1
		cmp 	ax,9
		mov 	dx,offset error1_9
		je 		write_message1
		
	write_message1:
		call	 PRINT
		ret
ERROR_PROCESSING1 ENDP

CLEAR_MEMORY PROC NEAR
		mov 	bx,offset LAST_BYTE 
		mov 	ax,es 
		sub 	bx,ax 
		mov 	cl,4h
		shr 	bx,cl 
		mov 	ah,4Ah 
		int 	21h
		jnc 	end_clear 
	
		call 	ERROR_PROCESSING1
		xor		al,al
		mov		ah,4Ch
		int 	21h
	end_clear:
		ret
CLEAR_MEMORY ENDP

VARIABLES_FUNC PROC NEAR
	get_variables:
		inc 	cx
		mov		al, es:[bx]
		inc 	bx
		cmp 	al, 0
		jz 		check_end
		loop 	get_variables
	
	check_end:
		cmp 	byte PTR es:[bx], 0
		jnz 	get_variables
		add 	bx, 3
		mov 	si, offset OVERLAY_PATH
	ret
VARIABLES_FUNC ENDP

PATH_FUNC PROC NEAR
	get_path:
		mov 	al, es:[bx]
		mov 	[si], al
		inc 	si
		inc 	bx
		cmp 	al, 0
		jz 		check_path
		jmp 	get_path
	
	check_path:	
		sub 	si, 9
		mov 	di, bp
	ret
PATH_FUNC ENDP

GET_OVL_PATH PROC NEAR
		push 	ax
		push 	bx
		push 	cx
		push 	dx
		push 	si
		push 	di
		push 	es	
		mov 	es, KEEP_PSP
		mov 	ax, es:[2Ch]
		mov 	es, ax
		mov 	bx, 0
		mov 	cx, 2
	
		call 	VARIABLES_FUNC
		call 	PATH_FUNC
		
	get_way:
		mov 	ah, [di]
		mov 	[si], ah
		cmp 	ah, 0
		jz 		check_way
		inc 	di
		inc 	si
		jmp 	get_way
		
	check_way:
		pop 	es
		pop 	di
		pop 	si
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax
		ret
GET_OVL_PATH ENDP

SIZE_OF_OVL	 PROC NEAR
		push	bx
		push 	es
		push 	si

		push 	ds
		push 	dx
		mov 	dx, SEG DTA
		mov 	ds, dx
		mov 	dx, offset DTA	
		mov 	ax, 1A00h		
		int 	21h
		pop 	dx
		pop 	ds
		
		push 	ds
		push 	dx
		xor 	cx, cx			
		mov 	dx, SEG OVERLAY_PATH	
		mov 	ds, dx
		mov 	dx, offset OVERLAY_PATH	
		mov 	ax, 4E00h
		int 	21h
		pop 	dx
		pop 	ds

		jnc 	no_err_size 		
		cmp 	ax, 2
		je 		err1			
		cmp 	ax, 3
		je 		err2
		jmp 	no_err_size
				
	err1:
		mov 	dx, offset error2_2
		call 	PRINT
		jmp 	exit
		
	err2:
		mov 	dx, offset error2_3
		call 	PRINT
		jmp 	exit
			
	no_err_size:
		push 	es
		push 	bx
		push 	si
		mov 	si, offset DTA
		add 	si, 1Ch		
		mov 	bx, [si]
		
		sub 	si, 2	
		mov 	bx, [si]	
		push 	cx
		mov 	cl, 4
		shr 	bx, cl 
		pop 	cx
		mov 	ax, [si+2] 
		push 	cx
		mov 	cl, 12
		sal 	ax, cl	
		pop 	cx
		add 	bx, ax	
		add 	bx, 2
		mov 	ax, 4800h	
		int 	21h			
		mov 	OVERLAY_ADDRESS, ax	
		pop 	si
		pop 	bx
		pop 	es

	exit:
		pop 	si
		pop 	es
		pop 	bx
		ret
SIZE_OF_OVL  ENDP

ERROR_PROCESSING3 PROC NEAR
		cmp 	ax, 1
		mov 	dx, offset error3_1
		je 		write_message3
	
		cmp 	ax, 2
		mov 	dx, offset error3_2
		je 		write_message3
	
		cmp 	ax, 3
		mov 	dx, offset error3_3
		je 		write_message3
	
		cmp 	ax, 4
		mov 	dx, offset error3_4
		je 		write_message3
	
		cmp 	ax, 5
		mov 	dx, offset error3_5
		je 		write_message3
	
		cmp 	ax, 8
		mov 	dx, offset error3_8
		je 		write_message3
	
		cmp 	ax, 10
		mov 	dx, offset error3_10
		je 		write_message3
		
	write_message3:
		call 	PRINT	
		ret
ERROR_PROCESSING3 ENDP

NO_ERROR_RUN PROC NEAR
		mov 	ax, SEG DATA
		mov 	ds, ax	
		mov 	ax, OVERLAY_ADDRESS
		mov 	WORD PTR OVERLAY_ADDR+2, ax
		call 	OVERLAY_ADDR
		mov 	ax, OVERLAY_ADDRESS
		mov 	es, ax
		mov 	ax, 4900h
		int 	21h
		mov 	ax, SEG DATA
		mov 	ds, ax
		ret
NO_ERROR_RUN ENDP

RUN_OVL PROC NEAR
		push 	bp
		push 	ax
		push 	bx
		push 	cx
		push 	dx
			
		mov 	bx, SEG OVERLAY_ADDRESS
		mov 	es, bx
		mov 	bx, offset OVERLAY_ADDRESS	
			
		mov 	dx, SEG OVERLAY_PATH
		mov 	ds, dx	
		mov 	dx, offset OVERLAY_PATH
			
		push 	ss
		push 	sp
			
		mov 	ax, 4B03h	
		int 	21h
		jnc 	no_error_way
		
		call	ERROR_PROCESSING3
		jmp		exit_way
no_error_way:
		call 	NO_ERROR_RUN
exit_way:
		pop 	sp
		pop 	ss
		mov 	es, KEEP_PSP
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax	
		pop 	bp
		ret
RUN_OVL ENDP	


MAIN PROC FAR
		mov 	ax, seg DATA
		mov 	ds, ax
		mov 	KEEP_PSP, es
		call 	CLEAR_MEMORY
	
		mov 	bp, offset str_overlay1
		call 	GET_OVL_PATH
		call 	SIZE_OF_OVL
		call 	RUN_OVL
		
		mov 	bp, offset str_overlay2
		call 	GET_OVL_PATH
		call 	SIZE_OF_OVL
		call 	RUN_OVL
	
		xor 	al, al
		mov 	ah, 4Ch
		int 	21H 
		ret
MAIN ENDP
CODE ENDS

LAST_BYTE SEGMENT	
LAST_BYTE ENDS	

END MAIN