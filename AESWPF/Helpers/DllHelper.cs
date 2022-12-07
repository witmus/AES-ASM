using System;
using System.Runtime.InteropServices;

namespace AESWPF.Helpers
{
    public static class AsmDllHelper
    {
        //[DllImport(@"C:\Users\witek\source\repos\AESWPF\x64\Debug\AESasm.dll")]
        [DllImport(@".\libs\AESasm.dll")]
        public static extern void Aes(byte[] input, byte[] keys, byte[] sbox);
    }

    public static class CppDllHelper
    {
        //[DllImport(@"C:\Users\witek\source\repos\AESWPF\x64\Debug\AEScpp.dll")]
        [DllImport(@".\libs\AEScpp.dll")]
        public static extern void Aes(byte[] input, byte[] keys, byte[] sbox);
    }

    public static class DllHelper
    {
        public static Action<byte[], byte[], byte[]> Aes(int choice)
        {
            return choice switch
            {
                0 => AsmDllHelper.Aes,
                1 => CppDllHelper.Aes
            };
        }
    }
}
