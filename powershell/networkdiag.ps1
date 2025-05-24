# Network Diagnostics Script
param(
    [switch]$Verbose = $false
)

# Create a timestamped output filename
$datetime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$outputFile = "network_test_results_$datetime.txt"

# Function to write log messages
function Write-Log {
    param([string]$Message)
    Add-Content -Path $outputFile -Value $Message
    if ($Verbose) { Write-Host $Message }
}

# Start logging
Write-Host "Beginning Network Test. Please wait about 20 seconds."
Add-Content -Path $outputFile -Value "Network Test Results"
Add-Content -Path $outputFile -Value "===================="
Add-Content -Path $outputFile -Value ""

# Section: Get Router IP
Write-Log "~~~~~~Get Router IP~~~~~~"
Write-Log "Pinging Google DNS (8.8.8.8) with TTL of 1 to find router IP..."

# Find router IP
try {
    $routerIP = (Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop | Select-Object -First 1
    Write-Log "Router IP Address: $routerIP"
}
catch {
    Write-Log "Failed to retrieve router IP."
    exit 1
}

# Section: Ping Home Router
Write-Log ""
Write-Log "~~~~~~Ping Home Router~~~~~~"
Write-Log "Pinging the home router ($routerIP) 10 times..."
(ping $routerIP -n 10) | ForEach-Object { Write-Log $_ }

# Section: Ping Google IP
Write-Log ""
Write-Log "~~~~~~Ping Google IP~~~~~~"
Write-Log "Pinging Google DNS (8.8.8.8) 10 times..."
(ping 8.8.8.8 -n 10) | ForEach-Object { Write-Log $_ }

# Section: Ping Google By Name
Write-Log ""
Write-Log "~~~~~~Ping Google By Name~~~~~~"
Write-Log "Pinging Google DNS (dns.google.com) 10 times..."
(ping dns.google.com -n 10) | ForEach-Object { Write-Log $_ }

# Section: Netstat Quality Stats
Write-Log ""
Write-Log "~~~~~~Netstat for Quality Stats~~~~~~"
Write-Log "Running netstat -es..."
(netstat -es) | ForEach-Object { Write-Log $_ }

# Section: Wi-Fi Connection
Write-Log ""
Write-Log "~~~~~~Netsh for Wi-Fi Connection~~~~~~"
Write-Log "Checking wifi connection information..."
(netsh wlan show interfaces) | ForEach-Object { Write-Log $_ }

# Section: Interface State
Write-Log ""
Write-Log "~~~~~~Netsh for Interface State~~~~~~"
Write-Log "Checking to ensure an Ethernet interface shows as connected (VPN link)..."
(netsh interface show interface) | ForEach-Object { Write-Log $_ }

# Section: Speedtest CLI Download and Test
Write-Log ""
Write-Log "~~~~~~Speedtest CLI Download and Test~~~~~~"

# Create a directory for tools if it doesn't exist
$toolsDir = "$env:USERPROFILE\NetworkTools"
if (!(Test-Path -Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

# Alternative download method using winget
try {
    Write-Log "Attempting to install Speedtest CLI using winget..."
    winget install Ookla.Speedtest.CLI -h --accept-source-agreements
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 10
}
catch {
    Write-Log "No installation method available. Please manually download Speedtest CLI."
}

# Try to run Speedtest CLI
try {
    Write-Log "Attempting to run Speedtest..."
    $speedtestPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\WinGet\Packages\Ookla.Speedtest.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\speedtest.exe"
    $speedtestResult = & $speedtestPath -f json
    
    if ($speedtestResult) {
        $parsedResults = $speedtestResult | ConvertFrom-Json

        # Log detailed results
        Write-Log "Speedtest Results:"
        Write-Log "Download Speed: $("{0:N2}" -f $parsedResults.download.bandwidth/100000) Mbps"
        Write-Log "Upload Speed: $("{0:N2}" -f $parsedResults.upload.bandwidth/100000) Mbps"
        Write-Log "Ping: $("{0:N2}" -f $parsedResults.ping.latency) ms"
        Write-Log "ISP: $($parsedResults.isp)"
        Write-Log "Server: $($parsedResults.server.name)"
    }
    else {
        Write-Log "Speedtest CLI did not return any results."
    }
}
catch {
    Write-Log "Speedtest execution failed: $_"
    exit 1
}
# Completion
Write-Log ""
Write-Log "~~~~~~ALL TESTS COMPLETE~~~~~~"
Write-Log ""
Write-Log "Network test completed. Results saved to $outputFile."

# Optional: Open the log file after completion
Invoke-Item $outputFile