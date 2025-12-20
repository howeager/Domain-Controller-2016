# ====== Settings ======
$OutCsv = ".\local_user_passwords.csv"
$Length = 20  # password length

# Character sets (exclude confusing chars if you want)
$Lower = "abcdefghijklmnopqrstuvwxyz"
$Upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
$Digits = "0123456789"
$Symbols = "!@#$%^&*()-_=+[]{};:,.?/"

$All = ($Lower + $Upper + $Digits + $Symbols).ToCharArray()

function New-RandomPassword {
    param([int]$Len = 20)

    # Ensure complexity: at least 1 from each set
    $pwChars = @()
    $pwChars += $Lower[(Get-Random -Minimum 0 -Maximum $Lower.Length)]
    $pwChars += $Upper[(Get-Random -Minimum 0 -Maximum $Upper.Length)]
    $pwChars += $Digits[(Get-Random -Minimum 0 -Maximum $Digits.Length)]
    $pwChars += $Symbols[(Get-Random -Minimum 0 -Maximum $Symbols.Length)]

    # Fill the rest
    for ($i = $pwChars.Count; $i -lt $Len; $i++) {
        $pwChars += $All[(Get-Random -Minimum 0 -Maximum $All.Length)]
    }

    # Shuffle so the first 4 aren't predictable
    -join ($pwChars | Sort-Object { Get-Random })
}

# Get local users (skip disabled + built-in/service-ish accounts)
$Users = Get-LocalUser |
    Where-Object {
        $_.Enabled -eq $true -and
        $_.Name -notmatch '^(Administrator|Guest|DefaultAccount|WDAGUtilityAccount)$'
    } |
    Select-Object -ExpandProperty Name

# Generate output objects
$Rows = foreach ($u in $Users) {
    [pscustomobject]@{
        username = $u
        password = (New-RandomPassword -Len $Length)
    }
}

# Write CSV with header: username,password
$Rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

Write-Host "Wrote: $OutCsv"
