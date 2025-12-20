# DC Firewall Configuration and Active Connection Monitor
# Run this script as Administrator
#This Script is for a 2016 DC Firewall Configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "2016 DC FIREWALL CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Enables a stateful firewall
Write-Host "[1/8] Enabling stateful firewall..." -ForegroundColor Yellow
netsh advfirewall set allprofiles state on

# Sets the firewall policy to block inbound and allow outbound
Write-Host "[2/8] Setting firewall policy (block inbound, allow outbound)..." -ForegroundColor Yellow
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

# Allows ping requests
Write-Host "[3/8] Allowing ping (ICMPv4) requests..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="ping" dir=in action=allow protocol=icmpv4

# Allows DNS requests to the domain controller
Write-Host "[4/8] Allowing DNS requests to 192.168.220.17..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="dns" dir=out action=allow remoteport=53 protocol=udp remoteip=192.168.1.17

# Enables logging of dropped connections
Write-Host "[5/8] Enabling logging for dropped connections..." -ForegroundColor Yellow
netsh advfirewall set allprofiles logging droppedconnections enable

# Allows Active Directory Domain Services
Write-Host "[6/8] Enabling Active Directory Domain Services rules..." -ForegroundColor Yellow
netsh advfirewall firewall set rule group="Active Directory Domain Services" new enable=yes

Write-Host "[7/8] Blocking Port 135!`n" -ForegroundColor Green
netsh advfirewall firewall add rule name="block_port_135" dir=in action=block protocol=tcp localport=135

Write-Host "[8/8] Blocking Port 445!`n" -ForegroundColor Green
#Only allow if there the IIS Servers have interdependencies on it
#netsh advfirewall firewall add rule name="block_port_445" dir=in action=block protocol=tcp localport=445





# Wait a moment for connections to stabilize
Start-Sleep -Seconds 2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ACTIVE NETWORK CONNECTIONS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Display all active TCP connections
Write-Host "ESTABLISHED TCP CONNECTIONS:" -ForegroundColor Green
Get-NetTCPConnection -State Established | 
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess |
    ForEach-Object {
        $processName = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        $_ | Add-Member -NotePropertyName ProcessName -NotePropertyValue $processName -PassThru
    } |
    Format-Table -AutoSize

Write-Host "`nLISTENING TCP PORTS:" -ForegroundColor Green
Get-NetTCPConnection -State Listen | 
    Select-Object LocalAddress, LocalPort, State, OwningProcess |
    ForEach-Object {
        $processName = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        $_ | Add-Member -NotePropertyName ProcessName -NotePropertyValue $processName -PassThru
    } |
    Format-Table -AutoSize

Write-Host "`nUDP ENDPOINTS:" -ForegroundColor Green
Get-NetUDPEndpoint | 
    Select-Object LocalAddress, LocalPort, OwningProcess |
    ForEach-Object {
        $processName = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        $_ | Add-Member -NotePropertyName ProcessName -NotePropertyValue $processName -PassThru
    } |
    Format-Table -AutoSize

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CONNECTION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$established = (Get-NetTCPConnection -State Established).Count
$listening = (Get-NetTCPConnection -State Listen).Count
$udp = (Get-NetUDPEndpoint).Count

Write-Host "Established TCP Connections: $established" -ForegroundColor White
Write-Host "Listening TCP Ports: $listening" -ForegroundColor White
Write-Host "UDP Endpoints: $udp" -ForegroundColor White

Write-Host "`nScript completed successfully!" -ForegroundColor Green