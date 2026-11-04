Add-Type -AssemblyName System.Windows.Forms
[void][System.Windows.Forms.MessageBox]::Show($env:UPDATE_MESSAGE, 'Update Notification Service')
