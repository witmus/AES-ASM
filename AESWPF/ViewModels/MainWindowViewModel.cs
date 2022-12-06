using AESWPF.Commands;
using AESWPF.Helpers;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;

namespace AESWPF.ViewModels
{
    class MainWindowViewModel : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        public double MilisecondsSum { get; set; }

        //private string _inputFilePath = @"C:\Users\witek\Desktop\Studia\JA\test_VerySmol.txt";
        private string _inputFilePath;
        public string InputFilePath
        {
            get => _inputFilePath;
            set
            {
                _inputFilePath = value;
                OnPropertyChanged();
            }
        }

        //private string _keyValue = "Thats my Kung Fu";
        private string _keyValue;
        public string KeyValue
        {
            get => _keyValue;
            set
            {
                _keyValue = value;
                OnPropertyChanged();
            }
        }

        private bool[] _libraryChoice = { true, false, false };
        public bool[] LibraryChoice
        {
            get => _libraryChoice;
        }
        public int SelectedLibrary
        {
            get => Array.IndexOf(_libraryChoice, true);
        }

        private string _threadsExponent = "2";
        public string ThreadsExponent
        {
            get => _threadsExponent;
            set
            {
                _threadsExponent = value;
                var exp = int.Parse(value);
                ThreadsCount = (Math.Pow(2, exp)).ToString();
                OnPropertyChanged();
            }
        }

        private string _threadsCount = "4";
        public string ThreadsCount
        {
            get => _threadsCount;
            set
            {
                _threadsCount = value;
                OnPropertyChanged();
            }
        }

        private string _timeResult = string.Empty;
        public string TimeResult
        {
            get => _timeResult;
            set
            {
                _timeResult = value;
                OnPropertyChanged();
            }
        }

        #region Commands

        public ICommand OpenFileDialogCommand { get; set; }

        private void OpenFileDialog(object param)
        {
            var fileDialog = new OpenFileDialog();
            fileDialog.Filter = "Text files (*.txt)|*.txt";
            if(fileDialog.ShowDialog() == true)
            {
                InputFilePath = fileDialog.FileName;
            }
        }

        public ICommand ExecuteCipheringCommand { get; set; }

        private void ExecuteCiphering(object param)
        {
            var keys = KeyExpansionHelper.KeyExpansion(KeyValue);

            var input = File.ReadAllBytes(InputFilePath);

            if (input.Length % 16 != 0)
            {
                var difference = 16 - input.Length % 16;
                var padded = new byte[difference];
                input = input.Concat(padded).ToArray();
            }

            keys = TransposeRoundKeys(keys);

            var aes = DllHelper.Aes(SelectedLibrary);

            var cipheredBytes = CipherBytes(input, keys, aes);
            var cipheredBase64String = Convert.ToBase64String(cipheredBytes);

            var resultPathBin = @"./secretBinaryMessage.bin";
            var resultPathTxt = @"./secretTextMessage.txt";

            File.WriteAllBytes(resultPathBin, cipheredBytes);
            File.WriteAllText(resultPathTxt, cipheredBase64String);
        }

        private bool CanExecuteCiphering(object param)
        {
            return !string.IsNullOrWhiteSpace(InputFilePath) && KeyValue?.Length == 16;
        }

        private byte[] CipherBytes(byte[] bytes, byte[][] keys, Action<byte[], byte[], byte[], int> aes)
        {
            var result = Array.Empty<byte>();

            var totalBytesCount = bytes.Length;
            var totalBlocksCount = (int)(totalBytesCount / 16);

            int offset;
            var threadsCount = int.Parse(ThreadsCount);
            var blocksCountPerThread = (int)(totalBlocksCount / threadsCount);
            var bytesCountPerThread = blocksCountPerThread * 16;

            byte[][] threadBlocks = new byte[threadsCount][];

            for(var i = 0; i < threadsCount - 1; i++)
            {
                offset = bytesCountPerThread * i;
                threadBlocks[i] = bytes[offset..(offset + bytesCountPerThread)];
            }

            int lastBlockIndex = threadsCount - 1;
            offset = bytesCountPerThread * lastBlockIndex;
            threadBlocks[lastBlockIndex] = bytes[offset..];

            var start = DateTime.Now;

            var threadsArray = new Thread[threadsCount];
            for(int i = 0; i < threadsCount; i++)
            {
                threadsArray[i] = StartThread(threadBlocks[i], keys, aes);
            }
            for (int i = 0; i < threadsCount; i++)
            {
                threadsArray[i].Join();
            }

            var end = DateTime.Now;
            foreach(var block in threadBlocks)
                result = result.Concat(block).ToArray();

            var executionTime = (end - start).TotalMilliseconds;
            MilisecondsSum += executionTime;
            TimeResult = executionTime.ToString();
            return result;
        }

        private Thread StartThread(byte[] input, byte[][] keys, Action<byte[], byte[], byte[], int> aes)
        {
            var thread = new Thread(() => CipherBlock(input, keys, aes));
            thread.Start();
            return thread;
        }

        private static void CipherBlock(byte[] input, byte[][] keys, Action<byte[], byte[], byte[], int> aes)
        {
            byte[] state;
            for (int i = 0; i < input.Length; i += 16)
            {
                state = input[i..(i + 16)];
                state = TransposeFourByFour(state);

                AesCSharp.ApplyRoundKey(state, keys[0]);

                for (short l = 1; l <= 10; l++)
                {
                    aes(state, keys[l], SBox.SBoxBytes, l);
                }

                state = TransposeFourByFour(state);

                for (int k = 0; k < 16; k++)
                {
                    input[i + k] = state[k];
                }
            }
        }

        private static byte[][] TransposeRoundKeys(byte[][] keys)
        {
            var result = new byte[11][];

            for(int i = 0; i < 11; i++)
            {
                result[i] = TransposeFourByFour(keys[i]);
            }

            return result;
        }

        private static byte[] TransposeFourByFour(byte[] matrix)
        {
            var result = new byte[16];

            for (var j = 0; j < 4; j++)
            {
                for (var k = 0; k < 4; k++)
                {
                    result[j * 4 + k] = matrix[j + k * 4];
                }
            }

            return result;
        }

        public ICommand ExecuteBatchTestingCommand { get; set; }

        private void ExecuteBatchTesting(object param)
        {
            MilisecondsSum = 0;
            for(int i = 0; i < 100; i++)
            {
                ExecuteCiphering(param);
            }
            TimeResult = (MilisecondsSum / 100).ToString();
        }

        #endregion

        public MainWindowViewModel()
        {
            OpenFileDialogCommand = new RelayCommand(OpenFileDialog);
            ExecuteCipheringCommand = new RelayCommand(ExecuteCiphering, CanExecuteCiphering);
            ExecuteBatchTestingCommand = new RelayCommand(ExecuteBatchTesting);
        }

        private void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
