using System;
using System.Runtime.InteropServices;

namespace AESWPF.Helpers
{
    public static class AsmDllHelper
    {
        [DllImport(@"C:\Users\witek\source\repos\AESWPF\x64\Release\AESasm.dll")]
        public static extern void Aes(byte[] input, byte[] key, byte[] sbox, int round);
    }

    public static class CppDllHelper
    {
        [DllImport(@"C:\Users\witek\source\repos\AESWPF\x64\Release\AEScpp.dll")]
        public static extern void Aes(byte[] input, byte[] key, byte[] sbox, int round);
    }

    public static class DllHelper
    {
        public static Action<byte[], byte[], byte[], int> Aes(int choice)
        {
            return choice switch
            {
                0 => AsmDllHelper.Aes,
                1 => CppDllHelper.Aes
            };
        }
    }
}
