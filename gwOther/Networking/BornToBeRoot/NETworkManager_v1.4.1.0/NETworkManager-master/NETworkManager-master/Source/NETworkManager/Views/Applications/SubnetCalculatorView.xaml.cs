using NETworkManager.ViewModels.Applications;
using System.Windows.Controls;

namespace NETworkManager.Views.Applications
{
    public partial class SubnetCalculatorView : UserControl
    {
        private SubnetCalculatorIPv4CalculatorViewModel viewModel = new SubnetCalculatorIPv4CalculatorViewModel();

        public SubnetCalculatorView()
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }
}
