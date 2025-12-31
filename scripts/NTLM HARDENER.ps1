<#
NTLM hardening (Domain Controller-focused) for Windows Server 2016
This script:
1) Disables storing LM hashes (safe)
2) Enables NTLM auditing for inbound/outbound (safer first step)
3) Provides OPTIONAL enforcement (commented out)

Reboot recommended.
#>

function Set-RegDword($path, $name, $value) {
    New-Item -Path $path -Force | Out-Null
    New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null
}

Write-Host "[*] Disabling LM hash storage..." -ForegroundColor Cyan


Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "NoLMHash" 1

Write-Host "[*] Enabling NTLM auditing..." -ForegroundColor Cyan
# 1 = Audit domain accounts, 2 = Audit all accounts
Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" "AuditReceivingNTLMTraffic" 2
Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" "AuditSendingNTLMTraffic" 2

Write-Host "[+] NTLM auditing enabled + LM hash storage disabled. Reboot recommended." -ForegroundColor Green
Write-Host "    Review Security log events for NTLM usage before enforcing blocks." -ForegroundColor Yellow

<#
OPTIONAL ENFORCEMENT (higher break risk) — uncomment only if you're sure:

# Restrict NTLM: NTLM authentication in this domain
# 3 = Deny for domain servers, 4 = Deny for domain accounts, 5 = Deny all (very risky)
Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" "RestrictNTLMInDomain" 3
#>
