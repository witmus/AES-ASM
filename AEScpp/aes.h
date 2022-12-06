#pragma once

#ifdef CPPLIB_EXPORTS
#define CPPLIB_API __declspec(dllexport)
#else
#define CPPLIB_API __declspec(dllimport)
#endif

extern "C" CPPLIB_API void Aes(unsigned char* state, unsigned char* key, unsigned char* sbox, short round);

void SubBytes(unsigned char* state, unsigned char* sbox);

void ShiftRows(unsigned char* state);

void MixColumns(unsigned char* state);

unsigned char MultiplyMatrixRows(unsigned char* a, unsigned char* b);

unsigned char MultiplyByTwo(unsigned char a);

unsigned char MultiplyByThree(unsigned char a);

void ApplyRoundKey(unsigned char* state, unsigned char* key);