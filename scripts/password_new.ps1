# ==============================
# Secure Password Generator
# ==============================
function New-SecurePassword {
    param (
        [int]$Length = 12
    )

    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower   = 'abcdefghijklmnopqrstuvwxyz'
    $digits  = '0123456789'
    $symbols = '!@#$%^&*()-_=+[]{}'
    $all     = $upper + $lower + $digits + $symbols

    # Ensure complexity
    $passwordChars = @(
        $upper   | Get-Random -Count 1
        $lower   | Get-Random -Count 1
        $digits  | Get-Random -Count 1
        $symbols | Get-Random -Count 1
    )

    # Fill remaining length securely
    $remaining = $Length - $passwordChars.Count
    $bytes = New-Object byte[] $remaining
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)

    foreach ($b in $bytes) {
        $passwordChars += $all[$b % $all.Length]
    }

    # Shuffle characters
    -join ($passwordChars | Sort-Object { Get-Random })
}

# ==============================
# Users to update
# ==============================
$users = @("User1", "User2", "User3", "User4", "User5")

# Output CSV
$outputFile = "C:\UserPasswords.csv"

# CSV header
"Username,Password" | Out-File $outputFile -Encoding UTF8

foreach ($user in $users) {
    try {
        # Generate secure password
        $password = New-SecurePassword 12
        $securePass = ConvertTo-SecureString $password -AsPlainText -Force

        # Update local user password
        Set-LocalUser -Name $user -Password $securePass

        # Output to console
        Write-Output "Updated: $user | New Password: $password"

        # Output to CSV
        "$user,$password" | Out-File $outputFile -Append -Encoding UTF8
    }
    catch {
        Write-Output "Failed to update $user — $($_.Exception.Message)"
    }
}

Write-Host "Password update complete. Output saved to: $outputFile"
