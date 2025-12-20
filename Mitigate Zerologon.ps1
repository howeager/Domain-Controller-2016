reg add "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
 /v FullSecureChannelProtection /t REG_DWORD /d 1 /f 
 
----------------------------------------------------

 $val = reg query "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v vulnerablechannelallowlist 2>$null

reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" /v vulnerablechannelallowlist /f 