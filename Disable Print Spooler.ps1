Stop-Service -Name "Spooler" -ErrorAction Stop
Set-Service -Name "Spooler" -StartupType Disabled