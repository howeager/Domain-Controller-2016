param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

function Read-File {
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
$users = Read-File -FilePath $InputFile |
    Where-Object { $_.Trim() -ne '' } |
    ForEach-Object { $_.Trim() }

foreach ($user in $users) {
    try {
        # Create local user with NO password
        New-LocalUser -Name $user -NoPassword -AccountNeverExpires

        Write-Host "Created user: $user" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create user $user — $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nUser creation complete." -ForegroundColor Yellow
