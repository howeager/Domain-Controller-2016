# Change-LocalUserPasswords.ps1
# Outputs CSV: username,pass
# Requires: PowerShell 5.1+ and running as Administrator.

param(
  [string]$OutCsv = ".\changed_passwords.csv",
  [int]$PasswordLength = 16
)

function New-RandomPassword {
  param([int]$Length = 16)

  # Simple strong-ish charset (avoids quotes/backticks to reduce CSV/shell issues)
  $lower = "abcdefghjkmnpqrstuvwxyz"
  $upper = "ABCDEFGHJKMNPQRSTUVWXYZ"
  $digits = "23456789"
  $special = "!@#$%^&*()-_=+[]{}.,?"

  $all = ($lower + $upper + $digits + $special).ToCharArray()

  # Ensure at least one char from each set
  $pwdChars = @()
  $pwdChars += ($lower.ToCharArray() | Get-Random -Count 1)
  $pwdChars += ($upper.ToCharArray() | Get-Random -Count 1)
  $pwdChars += ($digits.ToCharArray() | Get-Random -Count 1)
  $pwdChars += ($special.ToCharArray() | Get-Random -Count 1)

  $remaining = $Length - $pwdChars.Count
  if ($remaining -lt 0) { $remaining = 0 }

  $pwdChars += ($all | Get-Random -Count $remaining)

  # Shuffle
  -join ($pwdChars | Sort-Object { Get-Random })
}

# Check admin
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "Please run this script as Administrator."
  exit 1
}

Write-Host "Enter local usernames one per line. Press ENTER on a blank line to finish." -ForegroundColor Cyan

$usernames = @()
while ($true) {
  $u = Read-Host "Username"
  if ([string]::IsNullOrWhiteSpace($u)) { break }
  $usernames += $u.Trim()
}

if ($usernames.Count -eq 0) {
  Write-Error "No usernames provided."
  exit 1
}

$results = @()

foreach ($username in $usernames) {
  try {
    # Verify local user exists
    $null = Get-LocalUser -Name $username -ErrorAction Stop

    $newPass = New-RandomPassword -Length $PasswordLength
    $secure = ConvertTo-SecureString $newPass -AsPlainText -Force

    Set-LocalUser -Name $username -Password $secure -ErrorAction Stop

    $results += [pscustomobject]@{
      username = $username
      pass     = $newPass
    }

    Write-Host "Changed password for: $username" -ForegroundColor Green
  }
  catch {
    Write-Warning "Skipped '$username' (not found or failed): $($_.Exception.Message)"
  }
}

# Write CSV exactly as: username,pass (no extra columns)
"username,pass" | Out-File -FilePath $OutCsv -Encoding utf8
foreach ($row in $results) {
  "$($row.username),$($row.pass)" | Out-File -FilePath $OutCsv -Append -Encoding utf8
}

Write-Host "Done. CSV saved to: $OutCsv" -ForegroundColor Cyan
