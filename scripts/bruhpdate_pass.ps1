param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

function Read-File{
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        Get-Content $FilePath
    }
    else {
        Write-Error "File not found: $FilePath"
        exit 1
    }
}

# Read and parse usernames from file (remove empty lines and trim whitespace)
$users = Read-File -FilePath $InputFile | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }

# Prompt user for password base
Write-Host "Enter the base password (letters only recommended):" -ForegroundColor Cyan
$basePassword = Read-Host "Password"

# Validate that password was provided
if ([string]::IsNullOrWhiteSpace($basePassword)) {
    Write-Error "Password is required!"
    exit 1
}

# Output file on C drive
$output = "C:\UserPasswords.csv"

# Create CSV header
"Username,Password" | Out-File $output

# Non-letter characters only (numbers and symbols)
$nonLetterChars = "0123456789!@#$%^&*()"

foreach ($user in $users) {

    # Generate three random non-letter characters for this user
    $randomChars = -join ((1..3) | ForEach-Object { $nonLetterChars[(Get-Random -Maximum $nonLetterChars.Length)] })
    
    # Combine base password with the random characters
    $password = "$basePassword$randomChars"

    # Convert to secure string
    $securePass = ConvertTo-SecureString $password -AsPlainText -Force

    try {
        # Change the user's password
        Set-LocalUser -Name $user -Password $securePass
        # Output to CSV
        "$user,$password" | Out-File $output -Append
        Write-Host "Updated password for: $user" -ForegroundColor Green
    }
    catch {
        Write-Output "Failed to bruhpdate $user — $($_.Exception.Message)"
    }
}

Write-Host "`nPassword bruhpdate complete. Output saved to: $output" -ForegroundColor Yellow