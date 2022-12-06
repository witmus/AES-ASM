#include <cstring>
#include "pch.h"
#include "aes.h"

void Aes(unsigned char * state, unsigned char * key, unsigned char * sbox, short round)
{
    SubBytes(state, sbox);

    ShiftRows(state);

    if(round < 10)
        MixColumns(state);
    
    ApplyRoundKey(state, key);
}

void SubBytes(unsigned char* state, unsigned char* sbox)
{
	for (int i = 0; i < 16; i++) {
		state[i] = sbox[state[i]];
	}
}

void ShiftRows(unsigned char* state) {
	unsigned char* temp = new unsigned char[16];
    memcpy(temp, state, 16 * sizeof(unsigned char));
	//unsigned char* temp = state;

    state[0] = temp[0];
    state[1] = temp[1];
    state[2] = temp[2];
    state[3] = temp[3];

    state[4] = temp[5];
    state[5] = temp[6];
    state[6] = temp[7];
    state[7] = temp[4];

    state[8] = temp[10];
    state[9] = temp[11];
    state[10] = temp[8];
    state[11] = temp[9];

    state[12] = temp[15];
    state[13] = temp[12];
    state[14] = temp[13];
    state[15] = temp[14];

    delete[] temp;
}

void MixColumns(unsigned char* state)
{
    unsigned char column[4];
    unsigned char matrix[4][4] =
    {
        { 2, 3, 1, 1 },
        { 1, 2, 3, 1 },
        { 1, 1, 2, 3 },
        { 3, 1, 1, 2 }
    };

    unsigned char* temp = new unsigned char[16];
    memcpy(temp, state, 16 * sizeof(unsigned char));

    for (int i = 0; i < 4; i++)
    {
        column[0] = temp[i];
        column[1] = temp[i + 4];
        column[2] = temp[i + 8];
        column[3] = temp[i + 12];

        state[i] = MultiplyMatrixRows(matrix[0], column);
        state[i + 4] = MultiplyMatrixRows(matrix[1], column);
        state[i + 8] = MultiplyMatrixRows(matrix[2], column);
        state[i + 12] = MultiplyMatrixRows(matrix[3], column);
    }

    delete[] temp;
}

unsigned char MultiplyMatrixRows(unsigned char* a, unsigned char* b)
{
    unsigned char result[4];
    for (int i = 0; i < 4; i++)
    {
        switch (a[i])
        {
        case 1:
            result[i] = b[i];
            break;
        case 2:
            result[i] = MultiplyByTwo(b[i]);
            break;
        case 3:
            result[i] = MultiplyByThree(b[i]);
            break;
        }
    }

    return result[0] ^ result[1] ^ result[2] ^ result[3];
}

unsigned char MultiplyByTwo(unsigned char a)
{
    unsigned char result = a << 1;

    if (a > 0x7F)
        result ^= 0x1B;

    return result;
}

unsigned char MultiplyByThree(unsigned char a)
{
    return MultiplyByTwo(a) ^ a;
}

void ApplyRoundKey(unsigned char* state, unsigned char* key)
{
    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            state[i + j * 4] ^= key[i + j * 4];
        }
    }
}