using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AESWPF.Helpers
{
    public static class KeyExpansionHelper
    {
        /// <summary>
        /// Creates round keys using given initializing key
        /// </summary>
        /// <param name="key">Initial key passed by the user</param>
        /// <returns>Array of bytes representing round keys</returns>
        public static byte[][] KeyExpansion(string key)
        {
            var inputKeyBytes = Encoding.UTF8.GetBytes(key);

            var roundKeysBytes = new byte[176];

            for(int i = 0; i < 16; i++)
            {
                roundKeysBytes[i] = inputKeyBytes[i];
            }

            int rconIteration = 1;
            byte[] temp = new byte[4];
            int endIndex = 0;

            for (int i = 16; i < 11 * 4 * 4; i += 4)
            {
                for (int j = 0; j < 4; j++)
                    temp[j] = roundKeysBytes[i + j - 4];

                if(i % 16 == 0)
                    TransformWord(temp, ref rconIteration);

                for(int k = 0; k < 4; k++)
                {
                    roundKeysBytes[i + k] = roundKeysBytes[i + k - 16];
                    roundKeysBytes[i + k] ^= temp[k];
                }
            }

            var result = new byte[11][];
            for(int i = 0; i < 11; i++)
            {
                result[i] = new byte[16];
                for(int j = 0; j < 16; j++)
                    result[i][j] = roundKeysBytes[i * 16 + j];
            }

            return result;
        }

        private static void TransformWord(byte[] word, ref int rcon)
        {
            RotateWord(word);
            SubWord(word);

            word[0] ^= Rcon.RconBytes[rcon];
            rcon++;
        }

        private static void RotateWord(byte[] word)
        {
            var temp = word[0];

            word[0] = word[1];
            word[1] = word[2];
            word[2] = word[3];
            word[3] = temp;
        }

        private static void SubWord(byte[] word)
        {
            for(int i = 0; i < 4; i++)
            {
                word[i] = SBox.SBoxBytes[word[i]];
            }
        }
    }
}
