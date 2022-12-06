using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AESWPF.Helpers
{
    public static class AesCSharp
    {
        internal static void Aes(byte[] state, byte[] key, short round)
        {
            SubBytes(state);

            ShiftRows(state);

            if (round < 10)
                MixColumns(state);

            ApplyRoundKey(state, key);
        }

        internal static void ApplyRoundKey(byte[] state, byte[] key)
        {
            for (var i = 0; i < 4; i++)
            {
                for (var j = 0; j < 4; j++)
                {
                    state[i + j * 4] ^= key[i + j * 4];
                }
            }
        }

        private static void SubBytes(byte[] state)
        {
            for (var i = 0; i < 16; i++)
            {
                state[i] = SBox.SBoxBytes[state[i]];
            }
        }

        private static byte[] ShiftRows(byte[] state)
        {
            var result = new byte[16];

            result[0] = state[0];
            result[1] = state[1];
            result[2] = state[2];
            result[3] = state[3];

            result[4] = state[5];
            result[5] = state[6];
            result[6] = state[7];
            result[7] = state[4];

            result[8] = state[10];
            result[9] = state[11];
            result[10] = state[8];
            result[11] = state[9];

            result[12] = state[15];
            result[13] = state[12];
            result[14] = state[13];
            result[15] = state[14];

            return result;
        }

        private static byte[] MixColumns(byte[] state)
        {
            var result = new byte[16];
            var column = new byte[4];
            var matrix = new byte[4][]
            {
                new byte[4] { 2, 3, 1, 1 },
                new byte[4] { 1, 2, 3, 1 },
                new byte[4] { 1, 1, 2, 3 },
                new byte[4] { 3, 1, 1, 2 }
            };

            for (var i = 0; i < 4; i++)
            {
                column[0] = state[i];
                column[1] = state[i + 4];
                column[2] = state[i + 8];
                column[3] = state[i + 12];

                result[i] = MultiplyMatrixRows(matrix[0], column);
                result[i + 4] = MultiplyMatrixRows(matrix[1], column);
                result[i + 8] = MultiplyMatrixRows(matrix[2], column);
                result[i + 12] = MultiplyMatrixRows(matrix[3], column);
            }

            return result;
        }

        private static byte MultiplyMatrixRows(byte[] a, byte[] b)
        {
            var result = new byte[4];
            for (var i = 0; i < 4; i++)
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

            return (byte)(result[0] ^ result[1] ^ result[2] ^ result[3]);
        }

        private static byte MultiplyByTwo(byte a)
        {
            var result = (byte)(a << 1);

            if (a > 0x7F)
                result ^= 0x1B;

            return result;
        }

        private static byte MultiplyByThree(byte a)
        {
            return (byte)(MultiplyByTwo(a) ^ a);
        }
    }
}
