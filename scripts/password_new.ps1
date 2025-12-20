<# 
Simple Local User Password Changer (Server 2016 / PS 5.1)

- Resets passwords for selected local users
- Outputs a CSV with plaintext passwords (handle carefully)

TIP: Run as Admin
#>

function New-SecurePassword {
    param([int]$Length = 16)

    if ($Length -lt 12) { throw "Use Length >= 12 for better security." }

    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower   = 'abcdefghijklmnopqrstuvwxyz'
    $digits  = '0123456789'
    $symbols = '!@#$%^&*()-_=+[]{}'
    $all     = $upper + $lower + $digits + $symbols

    # Guarantee complexity (1 from each set)
    $chars = @(
        ($upper.ToCharArray()   | Get-Random -Count 1)
        ($lower.ToCharArray()   | Get-Random -Count 1)
        ($digits.ToCharArray()  | Get-Random -Count 1)
        ($symbols.ToCharArray() | Get-Random -Count 1)
    )

    $remaining = $Length - $chars.Count
    $bytes = New-Object byte[] $remaining
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }

    foreach ($b in $bytes) { $chars += $all[$b % $all.Length] }

    # Shuffle (ordering only)
    -join ($chars | Sort-Object { Get-Random })
}

# ====== CONFIG ======
# Option A: specify users explicitly (recommended)
$Usernames = @(
    "user1",
    "user2"
)

# Option B: uncomment to target ALL enabled local users except built-ins
# $Usernames = (Get-LocalUser |
#     Where-Object {
#         $_.Enabled -eq $true -and
#         $_.Name -notin @("Administrator","Guest","DefaultAccount","WDAGUtilityAccount")
#     } |
#     Select-Object -ExpandProperty Name)

$PasswordLength = 16
$CsvPath = "C:\LocalUserPasswords.csv"
# ====================

$results = @()

foreach ($u in $Usernames) {
    try {
        $pw = New-SecurePassword -Length $PasswordLength
        $secure = ConvertTo-SecureString $pw -AsPlainText -Force

        # Reset password
        Set-LocalUser -Name $u -Password $secure

        $results += [pscustomobject]@{
            Username = $u
            Password = $pw
            Status   = "Success"
            Note     = ""
        }

        Write-Host "Updated $u"
    }
    catch {
        $results += [pscustomobject]@{
            Username = $u
            Password = ""
            Status   = "Failed"
            Note     = $_.Exception.Message
        }

        Write-Host "Failed $u: $($_.Exception.Message)"
    }
}

$results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Done. CSV saved to: $CsvPath"
