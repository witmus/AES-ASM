; void Aes(unsigned char * state, unsigned char * key, unsigned char * sbox, short round)

; uzyte rejestry
; state - rcx
; key - rdx
; sbox - r8
; round - r9
; iterator - r10
; additional iterator - r11
; processedRow/processedByte - r12d/r12b
; processedByte - r13b

.data
	STATE_SIZE DB 16												;rozmiar stanu w bajtach
	MATRIX_DIMENSION DB 4											;dlugosc i szerokosc macierzy przemnazanych w ramach mieszania kolumn
	MIX_MATRIX DB 2, 3, 1, 1, 1, 2, 3, 1, 1, 1, 2, 3, 3, 1, 1, 2	;macierz wspolczynnikow mieszania macierzy
	PARTIAL_ONE DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	PARTIAL_TWO DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	PARTIAL_THREE DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	PARTIAL_FOUR DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.code
	Aes proc
													;prolog
		push rbp
		mov rbp, rsp

		push rbx
		push r12
		push r13
		push r14
		push r15
													;zerowanie uzywanych rejestrow
		xor rax, rax
		xor rbx, rbx
		xorps xmm0, xmm0
		xorps xmm1, xmm1
		xorps xmm2, xmm2
		xorps xmm3, xmm3
		xorps xmm4, xmm4
		xor r10, r10
		xor r12, r12
		xor r13, r13

		mov r11b, 16								;zapis rozmiaru stanu w bajtach do rejestru r11b

		movdqu xmm1, [rcx]							;DEBUG wczytanie stanu
		movdqu xmm2, [rdx]							;DEBUG wczytanie klucza rundy

	sub_bytes:
		mov r12b, BYTE PTR [rcx + r10]				;wczytanie pierwszego bajtu stanu
		mov r12b, BYTE PTR [r8 + r12]				;podstawienie wartosci z tablicy sbox
		mov BYTE PTR [rcx + r10], r12b				;zapis podstawionej wartosci do stanu
		inc r10										;inkrementacja iteratora
		cmp r10b, STATE_SIZE						;sprawdzenie warunku stopu
		jl sub_bytes								;jesli nie ostatni bajt stanu wykonaj sub_bytes dla kolejnego bajtu

		xor r10, r10								;zerowanie iteratora

		movdqu xmm1, [rcx]							;DEBUG wczytanie stanu

	shift_rows:
		mov r12d, DWORD PTR [rcx + 4]				;wczytanie drugiego wiersza stanu (zgodnie z algorytmem pierwszy wiersz nie jest przesuwany)
		ror r12d, 8									;obrot wiersza
		mov DWORD PTR [rcx + 4], r12d				;zapis obroconego wiersza do stanu

		mov r12d, DWORD PTR [rcx + 8]				
		ror r12d, 16
		mov DWORD PTR [rcx + 8], r12d

		mov r12d, DWORD PTR [rcx + 12]				
		ror r12d, 24
		mov DWORD PTR [rcx + 12], r12d

		cmp r9b, 10
		je last_round

		xor r12, r12								;zerowanie rejestru danych
		xor r13, r13								
		xor r15, r15								
		xor rbx, rbx								
		xor rax, rax
		xorps xmm1, xmm1
		xorps xmm2, xmm2

		mov rbx, OFFSET MIX_MATRIX					;zapis adresu tablicy pomocniczej do rax

	mix_columns_outer:
		cmp r10b, MATRIX_DIMENSION					;sprawdzenie warunku stopu
		je mix_columns_finish						;jesli ostatni wiersz macierzy wspolczynnikow skoncz mieszanie kolumn
		xor r11, r11								;zerowanie iteratora zagniezdzonej petli

	mix_columns_inner:
		mov r15b, r10b								;obliczenie indeksu tablic pomocniczych
		sal r15b, 2
		add r15b, r11b

		mov rax, OFFSET PARTIAL_ONE					;zapis adresu tablicy pomocniczej do rax
		mov r12b, BYTE PTR [rcx + r11]				;pobranie bajtu ze stanu
		mov r13b, BYTE PTR [rbx + r10 * 4]			;pobranie wspolczynnika z macierzy
		call multiply_bytes
		mov BYTE PTR [rax + r15], r12b				;zaladowanie wyniku czesciowego do tablicy pomocniczej

		mov rax, OFFSET PARTIAL_TWO
		mov r12b, BYTE PTR [rcx + r11 + 4]
		mov r13b, BYTE PTR [rbx + r10 * 4 + 1]
		call multiply_bytes
		mov BYTE PTR [rax + r15], r12b
	
		mov rax, OFFSET PARTIAL_THREE
		mov r12b, BYTE PTR [rcx + r11 + 8]
		mov r13b, BYTE PTR [rbx + r10 * 4 + 2]
		call multiply_bytes
		mov BYTE PTR [rax + r15], r12b
	
		mov rax, OFFSET PARTIAL_FOUR
		mov r12b, BYTE PTR [rcx + r11 + 12]
		mov r13b, BYTE PTR [rbx + r10 * 4 + 3]
		call multiply_bytes
		mov BYTE PTR [rax + r15], r12b

		inc r11
		cmp r11b, MATRIX_DIMENSION
		je mix_columns_inner_finish
		jmp mix_columns_inner

	mix_columns_inner_finish:
		inc r10
		jmp mix_columns_outer

	multiply_bytes:
		cmp r13b, 2
		jg multiply_by_three
		je multiply_by_two
		ret

	multiply_by_two:
		mov r14b, r12b
		sal r12b, 1
		cmp r14, 07Fh
		jg mul_two_overflow
		ret

	mul_two_overflow:
		xor r12b, 01Bh
		ret

	multiply_by_three:
		mov r14b, r12b
		sal r12b, 1
		cmp r14, 07Fh
		jg mul_three_overflow
		xor r12b, r14b
		ret

	mul_three_overflow:
		xor r12b, 01Bh
		xor r12b, r14b
		ret

	mix_columns_finish:
		mov rax, OFFSET PARTIAL_ONE
		movdqu xmm1, [rax]
		mov rax, OFFSET PARTIAL_TWO
		movdqu xmm2, [rax]
		mov rax, OFFSET PARTIAL_THREE
		movdqu xmm3, [rax]
		mov rax, OFFSET PARTIAL_FOUR
		movdqu xmm4, [rax]

		xorps xmm1, xmm2
		xorps xmm1, xmm3
		xorps xmm1, xmm4
		jmp add_round_key
	
	last_round:
		movdqu xmm1, [rcx]

	add_round_key:
		movdqu xmm0, [rdx]
		xorps xmm1, xmm0
		movdqu XMMWORD PTR [rcx], xmm1

		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rax

		mov rsp, rbp								;epilog
		pop rbp
		ret

	Aes endp
	end