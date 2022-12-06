using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Security.Policy;

using AESWPF.ViewModels;
using System.Text.RegularExpressions;

namespace AESWPF
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            DataContext = new MainWindowViewModel();
        }

        private void KeyPreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            var regex = new Regex("[^a-zA-Z0-9]+");
            e.Handled = regex.IsMatch(e.Text);
        }

        private void RadioButton_Checked(object sender, RoutedEventArgs e)
        {

        }
    }
}
