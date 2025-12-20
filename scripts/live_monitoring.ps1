#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Real-time network connection and activity monitor
.DESCRIPTION
    Monitors live TCP/UDP connections, DNS queries, and Kerberos authentication events
.NOTES
    Requires Administrator privileges
#>

param(
    [switch]$ShowDNS,
    [switch]$ShowKerberos,
    [switch]$ShowConnections = $true,
    [switch]$ShowUDP,
    [int]$RefreshInterval = 3,
    [switch]$ExportToFile,
    [string]$LogPath = "C:\bruh_monitor.txt"
)

$ErrorActionPreference = "SilentlyContinue"

# Color scheme
$script:Colors = @{
    Header = "Cyan"
    Established = "Green"
    Listening = "Yellow"
    TimeWait = "Gray"
    DNS = "Magenta"
    Kerberos = "Blue"
    Error = "Red"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-LiveTCPConnections {
    $connections = Get-NetTCPConnection | Where-Object {
        $_.State -in @("Established", "Listen", "TimeWait", "CloseWait")
    }
    
    $connectionInfo = foreach ($conn in $connections) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                LocalAddress = $conn.LocalAddress
                LocalPort = $conn.LocalPort
                RemoteAddress = $conn.RemoteAddress
                RemotePort = $conn.RemotePort
                State = $conn.State
                PID = $conn.OwningProcess
                ProcessName = if($process) { $process.ProcessName } else { "Unknown" }
                ProcessPath = if($process) { $process.Path } else { "N/A" }
            }
        }
        catch {
            continue
        }
    }
    
    return $connectionInfo
}

function Get-LiveUDPEndpoints {
    $endpoints = Get-NetUDPEndpoint
    
    $endpointInfo = foreach ($ep in $endpoints) {
        try {
            $process = Get-Process -Id $ep.OwningProcess -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                LocalAddress = $ep.LocalAddress
                LocalPort = $ep.LocalPort
                PID = $ep.OwningProcess
                ProcessName = if($process) { $process.ProcessName } else { "Unknown" }
                ProcessPath = if($process) { $process.Path } else { "N/A" }
            }
        }
        catch {
            continue
        }
    }
    
    return $endpointInfo
}

function Get-RecentDNSQueries {
    param([int]$MaxEvents = 20)
    
    # Enable DNS client logging if not already enabled
    try {
        $dnsLog = Get-WinEvent -ListLog "Microsoft-Windows-DNS-Client/Operational" -ErrorAction SilentlyContinue
        if ($dnsLog -and -not $dnsLog.IsEnabled) {
            wevtutil.exe sl "Microsoft-Windows-DNS-Client/Operational" /e:true
        }
    }
    catch {}
    
    $dnsEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-DNS-Client/Operational'
        ID = 3008, 3020  # DNS query events
    } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
    
    $queries = foreach ($event in $dnsEvents) {
        try {
            $xml = [xml]$event.ToXml()
            $queryName = $xml.Event.EventData.Data | Where-Object {$_.Name -eq 'QueryName'} | Select-Object -ExpandProperty '#text'
            
            [PSCustomObject]@{
                Time = $event.TimeCreated
                Query = $queryName
                PID = $event.ProcessId
            }
        }
        catch {
            continue
        }
    }
    
    return $queries
}

function Get-RecentKerberosEvents {
    param([int]$MaxEvents = 20)
    
    $kerberosEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4768, 4769, 4770, 4771, 4772  # Kerberos events
    } -MaxEvents $MaxEvents -ErrorAction SilentlyContinue
    
    $tickets = foreach ($event in $kerberosEvents) {
        try {
            $xml = [xml]$event.ToXml()
            $eventData = $xml.Event.EventData.Data
            
            $eventType = switch ($event.Id) {
                4768 { "TGT Request" }
                4769 { "TGS Request" }
                4770 { "TGT Renewed" }
                4771 { "Pre-auth Failed" }
                4772 { "TGT Request Failed" }
            }
            
            [PSCustomObject]@{
                Time = $event.TimeCreated
                Type = $eventType
                User = ($eventData | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
                ServiceName = ($eventData | Where-Object {$_.Name -eq 'ServiceName'}).'#text'
                IPAddress = ($eventData | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
            }
        }
        catch {
            continue
        }
    }
    
    return $tickets
}

function Show-NetworkSnapshot {
    Clear-Host
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════════╗" -Color $Colors.Header
    Write-ColorOutput "║          I'm Watching You - $timestamp          ║" -Color $Colors.Header
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════════╝`n" -Color $Colors.Header
    
    if ($ShowConnections) {
        Write-ColorOutput "═══ TCP CONNECTIONS ═══" -Color $Colors.Header
        $tcpConns = Get-LiveTCPConnections
        
        $established = $tcpConns | Where-Object {$_.State -eq "Established"}
        $listening = $tcpConns | Where-Object {$_.State -eq "Listen"}
        
        Write-ColorOutput "`n▶ Established Connections: $($established.Count)" -Color $Colors.Established
        $established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, ProcessName, PID | 
            Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Colors.Established
        
        Write-ColorOutput "▶ Listening Ports: $($listening.Count)" -Color $Colors.Listening
        $listening | Select-Object LocalAddress, LocalPort, ProcessName, PID | 
            Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Colors.Listening
    }
    
    if ($ShowUDP) {
        Write-ColorOutput "`n═══ UDP ENDPOINTS ═══" -Color $Colors.Header
        $udpEndpoints = Get-LiveUDPEndpoints
        Write-ColorOutput "▶ Active UDP Endpoints: $($udpEndpoints.Count)" -Color "Yellow"
        $udpEndpoints | Select-Object LocalAddress, LocalPort, ProcessName, PID | 
            Format-Table -AutoSize | Out-String | Write-Host
    }
    
    if ($ShowDNS) {
        Write-ColorOutput "`n═══ RECENT DNS QUERIES ═══" -Color $Colors.Header
        $dnsQueries = Get-RecentDNSQueries
        if ($dnsQueries) {
            $dnsQueries | Select-Object Time, Query, PID | 
                Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Colors.DNS
        }
        else {
            Write-ColorOutput "  No recent DNS queries found. DNS logging may need to be enabled." -Color $Colors.Error
        }
    }
    
    if ($ShowKerberos) {
        Write-ColorOutput "`n═══ RECENT KERBEROS ACTIVITY ═══" -Color $Colors.Header
        $kerberosEvents = Get-RecentKerberosEvents
        if ($kerberosEvents) {
            $kerberosEvents | Select-Object Time, Type, User, ServiceName, IPAddress | 
                Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor $Colors.Kerberos
        }
        else {
            Write-ColorOutput "  No recent Kerberos events found." -Color $Colors.Error
        }
    }
    
    Write-ColorOutput "`n[Press CTRL+C to stop monitoring]" -Color "Gray"
    
    if ($ExportToFile) {
        $logEntry = @"
========================================
Timestamp: $timestamp
TCP Established: $($established.Count)
TCP Listening: $($listening.Count)
DNS Queries: $($dnsQueries.Count)
Kerberos Events: $($kerberosEvents.Count)
========================================

"@
        Add-Content -Path $LogPath -Value $logEntry
    }
}

# Main monitoring loop
Write-ColorOutput "`n[*] Starting Network Monitor..." -Color "Green"
Write-ColorOutput "[*] Refresh Interval: $RefreshInterval seconds" -Color "Green"

if ($ShowDNS) {
    Write-ColorOutput "[*] DNS Query Monitoring: Enabled" -Color "Green"
}
if ($ShowKerberos) {
    Write-ColorOutput "[*] Kerberos Monitoring: Enabled" -Color "Green"
}
if ($ShowUDP) {
    Write-ColorOutput "[*] UDP Monitoring: Enabled" -Color "Green"
}
if ($ExportToFile) {
    Write-ColorOutput "[*] Logging to: $LogPath" -Color "Green"
}

Start-Sleep -Seconds 2

try {
    while ($true) {
        Show-NetworkSnapshot
        Start-Sleep -Seconds $RefreshInterval
    }
}
catch {
    Write-ColorOutput "`n[!] Monitoring stopped." -Color "Red"
}

<#
.EXAMPLE
    .\LiveNetworkMonitor.ps1
    Basic monitoring of TCP connections

.EXAMPLE
    .\LiveNetworkMonitor.ps1 -ShowDNS -ShowKerberos -RefreshInterval 5
    Monitor TCP connections, DNS queries, and Kerberos events with 5 second refresh

.EXAMPLE
    .\LiveNetworkMonitor.ps1 -ShowDNS -ShowUDP -ExportToFile -LogPath "C:\logs\network.log"
    Monitor TCP/UDP connections and DNS with logging enabled
#>