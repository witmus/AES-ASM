; void Aes(unsigned char * state, unsigned char * key, unsigned char * sbox, short round)

; uzyte rejestry
; state - rcx
; key - rdx
; sbox - r8
; roundIterator - r9
; iterator - r10
; additional iterator - r11
; processedRow/processedByte - r12d/r12b
; processedByte - r13b

.data
	MIX_MATRIX DB 2, 3, 1, 1, 1, 2, 3, 1, 1, 1, 2, 3, 3, 1, 1, 2	;macierz wspolczynnikow mieszania macierzy
	MIX_COLUMNS_OUTPUT DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0			;tablica wyjsciowa operacji mix_columns

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

		xor r9, r9
		mov r9b, 1
		mov r11b, 16								;zapis rozmiaru stanu w bajtach do rejestru r11b

	start_round:
													;zerowanie uzywanych rejestrow
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
		mov r12b, BYTE PTR [rcx + r10]				;wczytanie pierwszego bajtu stanu
		mov r12b, BYTE PTR [r8 + r12]				;podstawienie wartosci z tablicy sbox
		mov BYTE PTR [rcx + r10], r12b				;zapis podstawionej wartosci do stanu
		inc r10										;inkrementacja iteratora
		cmp r10b, 16								;sprawdzenie warunku stopu
		jl sub_bytes								;jesli nie ostatni bajt stanu wykonaj sub_bytes dla kolejnego bajtu

		xor r10, r10								;zerowanie iteratora

	shift_rows:

		mov r12d, DWORD PTR [rcx + 4]				;wczytanie drugiego wiersza stanu (zgodnie z algorytmem pierwszy wiersz nie jest przesuwany)
		ror r12d, 8									;obrot wiersza
		mov DWORD PTR [rcx + 4], r12d				;zapis obroconego wiersza do stanu

		mov r12d, DWORD PTR [rcx + 8]				;wczytanie trzeciego wiersza stanu				
		ror r12d, 16
		mov DWORD PTR [rcx + 8], r12d

		mov r12d, DWORD PTR [rcx + 12]				;wczytanie czwartego wiersza stanu				
		ror r12d, 24
		mov DWORD PTR [rcx + 12], r12d

		cmp r9b, 10
		je last_round

		push r8										;przechowanie wskaznika na sbox na stosie
		push r9										;przechowanie iteratora rundy na stosie
		
		xor r12, r12								;zerowanie rejestru danych

		mov rax, OFFSET MIX_COLUMNS_OUTPUT			;zapis adresu tablicy wynikowej dla mix_columns
		mov rbx, OFFSET MIX_MATRIX					;zapis adresu tablicy wspolczynnikow

	mix_columns_outer:
		cmp r10b, 4									;sprawdzenie warunku stopu
		je mix_columns_finish						;jesli ostatni wiersz macierzy wspolczynnikow skoncz mieszanie kolumn
		xor r11, r11								;zerowanie iteratora kolumny stanu
		mov r15d, DWORD PTR [rbx + r10 * 4]			;wczytanie wiersza macierzy wspolczynnikow

	mix_columns_inner:
		xor r8, r8
		xor r9, r9

		mov r13d, r15d								;skopiowanie wspolczynnikow

		mov r12b, BYTE PTR [rcx + r11]				;pobranie bajtu ze stanu
		call multiply_bytes							;wywolanie procedury mnozenia bajtow
		xor r9b, r12b								;dodanie czesciowego wyniku do rejestru wyjsciowego
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
													;obliczenie adresu bajtu wynikowego
		mov r8, r10
		sal r8, 2									;przeniesienie indeksu wiersza i przemnozenie przez 4 
		add r8, r11									;dodanie indeksu kolumny
		mov BYTE PTR [rax + r8], r9b				;zapis obliczonego bajtu w tablicy wyjsciowej

		inc r11
		cmp r11b, 4
		je mix_columns_inner_finish
		jmp mix_columns_inner

	mix_columns_inner_finish:
		inc r10										;inkrementacja iteratora wiersza macierzy wspolczynnikow
		jmp mix_columns_outer

	multiply_bytes:
		cmp r13b, 2									;sprawdzenie wartosci wspolczynnika z macierzy stalych
		jg multiply_by_three
		je multiply_by_two
		ret

	multiply_by_two:
		sal r12b, 1									;przemnoz bajt przez 2
		jc mul_two_overflow							;jesli nastapilo przeniesienie najstarszego bitu wykonaj dodatkowa operacje
		ret											;powrot z procedury multiply_bytes

	mul_two_overflow:
		xor r12b, 01Bh
		ret											;powrot z procedury multiply_bytes

	multiply_by_three:
		mov r14b, r12b								;rozbicie mnozenia przez 3 na dwie osobne operacje
		sal r12b, 1
		jc mul_three_overflow
		xor r12b, r14b
		ret

	mul_three_overflow:
		xor r12b, 01Bh
		xor r12b, r14b
		ret

	mix_columns_finish:
		pop r9										;odzyskanie wartosci ze stosu
		pop r8
		
		movdqu xmm1, [rax]							;wczytanie tablicy po mieszaniu kolumn
		jmp add_round_key
	
	last_round:
		movdqu xmm1, [rcx]							;w ostatniej rundzie nie nastepuje mieszanie kolumn, aktualna wartosc stanu jest wskazywana przez rcx

	add_round_key:
		sal r9, 4							;klucz rundy ma 16 bajtow, wiec indeks pierwszego bajtu klucza rundy = iterator rund * 16
		movdqu xmm0, [rdx + r9]				;wczytanie klucza rundy do xmm0
		sar r9, 4							;przywrocenie pierwotnej wartosci iteratora rundy
		xorps xmm1, xmm0					;dodanie klucza rundy do stanu
		movdqu XMMWORD PTR [rcx], xmm1		;uaktualnienie wartosci stanu

		inc r9										;inkrementacja iteratora rund
		cmp r9, 11
		jl start_round
		

	finish:
		pop r15										;przywrocenie pierwotnych wartosci rejestrow
		pop r14
		pop r13
		pop r12
		pop rbx

		mov rsp, rbp								;epilog
		pop rbp
		ret

	Aes endp
	end