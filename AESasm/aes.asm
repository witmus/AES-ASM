; void Aes(unsigned char * state, unsigned char * key, unsigned char * sbox, short round)

; used registers
; state - rcx
; key - rdx
; sbox - r8
; roundIterator - r9
; iterator - r10
; additional iterator - r11
; processedRow/processedByte - r12d/r12b
; processedByte - r13b

.data
	MIX_MATRIX DB 2, 3, 1, 1, 1, 2, 3, 1, 1, 1, 2, 3, 3, 1, 1, 2	;mix matrix coefficients
	MIX_COLUMNS_OUTPUT DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0			;mix_columns output

.code
	Aes proc
													;asm prologue
		push rbp
		mov rbp, rsp

		push rbx
		push r12
		push r13
		push r14
		push r15

		xor r9, r9
		mov r9b, 1
		mov r11b, 16

	start_round:
													;reset used registers
		xor rax, rax
		xor rbx, rbx
		xorps xmm0, xmm0
		xorps xmm1, xmm1
		xor r10, r10
		xor r12, r12
		xor r13, r13
		xor r14, r14
		xor r15, r15


	sub_bytes:
		mov r12b, BYTE PTR [rcx + r10]				;read first byte of state
		mov r12b, BYTE PTR [r8 + r12]				;sbox substitution
		mov BYTE PTR [rcx + r10], r12b				;write substituted value to state
		inc r10										;increment the state iterator
		cmp r10b, 16								;check stop condition
		jl sub_bytes

		xor r10, r10								;reset iterator

	shift_rows:

		mov r12d, DWORD PTR [rcx + 4]				;read second row of state, in this state the first one remains unchanged
		ror r12d, 8									;rotate the row
		mov DWORD PTR [rcx + 4], r12d				;write row to state

		mov r12d, DWORD PTR [rcx + 8]				;same for third row				
		ror r12d, 16
		mov DWORD PTR [rcx + 8], r12d

		mov r12d, DWORD PTR [rcx + 12]				;same for fourth row			
		ror r12d, 24
		mov DWORD PTR [rcx + 12], r12d

		cmp r9b, 10
		je last_round

		push r8										;store the sbox pointer on stach
		push r9										;store the round counter on stack
		
		xor r12, r12								;reset data register

		mov rax, OFFSET MIX_COLUMNS_OUTPUT			;move output pointer to RAX
		mov rbx, OFFSET MIX_MATRIX					;mov coefficients matrix pointer to RBX

	mix_columns_outer:
		cmp r10b, 4									;check if fourth column
		je mix_columns_finish
		xor r11, r11								;reset state column iterator
		mov r15d, DWORD PTR [rbx + r10 * 4]			;read row of coefficients

	mix_columns_inner:
		xor r8, r8
		xor r9, r9

		mov r13d, r15d

		mov r12b, BYTE PTR [rcx + r11]
		call multiply_bytes
		xor r9b, r12b								;add partial result to output register
		shr r13d, 8

		mov r12b, BYTE PTR [rcx + r11 + 4]
		call multiply_bytes
		xor r9b, r12b
		shr r13d, 8
	
		mov r12b, BYTE PTR [rcx + r11 + 8]
		call multiply_bytes
		xor r9b, r12b
		shr r13d, 8
	
		mov r12b, BYTE PTR [rcx + r11 + 12]
		call multiply_bytes
		xor r9b, r12b
													;calculate the result byte's address
		mov r8, r10
		sal r8, 2									;multiply row index by 4 
		add r8, r11									;add column index
		mov BYTE PTR [rax + r8], r9b				;write result byte to output

		inc r11
		cmp r11b, 4
		je mix_columns_inner_finish
		jmp mix_columns_inner

	mix_columns_inner_finish:
		inc r10
		jmp mix_columns_outer

	multiply_bytes:
		cmp r13b, 2									;check multiplication coefficient value, can be 1, 2, or 3
		jg multiply_by_three
		je multiply_by_two
		ret

	multiply_by_two:
		sal r12b, 1
		jc mul_two_overflow
		ret

	mul_two_overflow:
		xor r12b, 01Bh
		ret

	multiply_by_three:
		mov r14b, r12b								;x*3 = x*2 + x
		sal r12b, 1
		jc mul_three_overflow
		xor r12b, r14b
		ret

	mul_three_overflow:
		xor r12b, 01Bh
		xor r12b, r14b
		ret

	mix_columns_finish:
		pop r9										;retrieve pointers from stack
		pop r8
		
		movdqu xmm1, [rax]							;read result of mix_columns into XMM1
		jmp add_round_key
	
	last_round:
		movdqu xmm1, [rcx]							;in the last round the mix column stage doesnt occur

	add_round_key:
		sal r9, 4							;round_key_index = round * 16
		movdqu xmm0, [rdx + r9]
		sar r9, 4							;restore round iterator
		xorps xmm1, xmm0					;apply round key
		movdqu XMMWORD PTR [rcx], xmm1		;update state value

		inc r9										;increment round iterator
		cmp r9, 11
		jl start_round
		

	finish:
		pop r15										;restore registers values
		pop r14
		pop r13
		pop r12
		pop rbx

		mov rsp, rbp								;epilogue
		pop rbp
		ret

	Aes endp
	end