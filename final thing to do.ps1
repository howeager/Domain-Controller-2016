<#
Quick health checks after hardening (DC)
#>

Write-Host "[*] Running dcdiag (this may take a bit)..." -ForegroundColor Cyan
dcdiag

Write-Host "[*] Running repadmin /replsummary ..." -ForegroundColor Cyan
repadmin /replsummary

Write-Host "[*] Showing current domain controller discovery..." -ForegroundColor Cyan
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $domain = (Get-ADDomain).DNSRoot
    nltest /dsgetdc:$domain
} catch {
    Write-Host "[!] Could not query AD domain via PowerShell. Try: nltest /dsgetdc:yourdomain.local" -ForegroundColor Yellow
}

Write-Host "[+] Checks complete. Review any errors above." -ForegroundColor Green
