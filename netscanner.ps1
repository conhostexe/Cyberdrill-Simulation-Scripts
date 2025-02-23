param (
    [string]$rangeType = "all",  # Options: "all", "10", "172", "192"
    [int]$startIP = 1,           # Starting IP range
    [int]$endIP = 254,          # Ending IP range
    [int[]]$ports = @(22, 23, 80, 135, 139, 443, 445, 3389)  # Common ports to scan
)

# Define private IP ranges
$privateRanges = @{
    "10"  = "10.0.0"    # 10.0.0.0/8
    "172" = "172.16.0"  # 172.16.0.0/12
    "192" = "192.168.0" # 192.168.0.0/16
}

# Function to test if a port is open
function Test-Port {
    param (
        [string]$ip,
        [int]$port
    )
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connection = $tcpClient.BeginConnect($ip, $port, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne(100, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connection)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

# Function to scan network for an IP range and ports
function Scan-Host {
    param (
        [string]$ip
    )
    
    $result = [PSCustomObject]@{
        IPAddress = $ip
        Status    = "Offline"
        OpenPorts = @()
    }

    Write-Host "Pinging $ip..." -ForegroundColor Yellow

    # Test if host is alive
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        $result.Status = "Online"
        Write-Host "$ip is alive" -ForegroundColor Green
        
        # Scan each port
        $portResults = @()
        foreach ($port in $ports) {
            Write-Host "Scanning Port $port on $ip..." -ForegroundColor Cyan
            if (Test-Port -ip $ip -port $port) {
                Write-Host "Port $port is OPEN on $ip" -ForegroundColor Green
                $portResults += $port
            } else {
                Write-Host "Port $port is closed on $ip" -ForegroundColor Gray
            }
        }
        $result.OpenPorts = $portResults
    } else {
        Write-Host "$ip is offline" -ForegroundColor Red
    }

    return $result
}

# Function to scan entire network range
function Scan-Network {
    param (
        [string]$network
    )
    Write-Host "Starting network scan on $network.[$startIP-$endIP]..." -ForegroundColor Cyan
    Write-Host "Scanning ports: $($ports -join ', ')" -ForegroundColor Cyan

    $results = @()

    # Loop through IP range and scan synchronously
    for ($i = $startIP; $i -le $endIP; $i++) {
        $currentIP = "$network.$i"

        # Scan each IP sequentially
        $result = Scan-Host -ip $currentIP
        $results += $result
    }

    # Display results in table format
    Write-Host "`nScan Complete for $network! Results:" -ForegroundColor Cyan
    $results | Format-Table -AutoSize

    return $results
}

# Main execution
try {
    $allResults = @()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ($rangeType -eq "all") {
        foreach ($key in $privateRanges.Keys) {
            $network = $privateRanges[$key]
            $allResults += Scan-Network -network $network
        }
    } else {
        if ($privateRanges.ContainsKey($rangeType)) {
            $network = $privateRanges[$rangeType]
            $allResults += Scan-Network -network $network
        } else {
            Write-Host "Invalid range type. Use 'all', '10', '172', or '192'." -ForegroundColor Red
            exit
        }
    }
    
    # Export all results to CSV
    $allResults | Export-Csv -Path "NetworkScan_$timestamp.csv" -NoTypeInformation
    Write-Host "All results exported to NetworkScan_$timestamp.csv" -ForegroundColor Cyan
    
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
