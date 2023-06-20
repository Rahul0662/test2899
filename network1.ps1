$criticalThreshold = 90  # Adjust the threshold values as needed
$warningThreshold = 80

# Function to convert bytes to a human-readable format with appropriate units
function ConvertToReadableSize {
    param([double]$size)
    $units = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($size -ge 1024 -and $index -lt $units.Length) {
        $size /= 1024
        $index++
    }
    [Math]::Round($size, 2).ToString() + " " + $units[$index]
}

# Function to calculate the network bandwidth in megabits per second (Mb/s)
function CalculateNetworkBandwidth {
    param([double]$bytes, [int]$interval)
    $megabits = ($bytes * 8) / (1024 * 1024)
    $mbps = $megabits / $interval
    [Math]::Round($mbps, 2)
}

# Get active network interface name
$activeInterface = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name

# Check if the specified interface name exists, otherwise use the active interface name
$interfaceName = "Wi-Fi"
if (-not (Get-NetAdapter -Name $interfaceName -ErrorAction SilentlyContinue)) {
    $interfaceName = $activeInterface
}

# Get network interface statistics
$networkInterface = Get-NetAdapter | Where-Object { $_.Name -eq $interfaceName }
if ($networkInterface) {
    $interval = 1  # Interval in seconds

    $initialBytesReceived = $networkInterface | Get-NetAdapterStatistics | Select-Object -ExpandProperty ReceivedBytes
    $initialBytesSent = $networkInterface | Get-NetAdapterStatistics | Select-Object -ExpandProperty SentBytes

    Start-Sleep -Seconds $interval

    $finalBytesReceived = $networkInterface | Get-NetAdapterStatistics | Select-Object -ExpandProperty ReceivedBytes
    $finalBytesSent = $networkInterface | Get-NetAdapterStatistics | Select-Object -ExpandProperty SentBytes

    $receivedBytes = $finalBytesReceived - $initialBytesReceived
    $sentBytes = $finalBytesSent - $initialBytesSent

    $receivedTraffic = ConvertToReadableSize -size $receivedBytes
    $sentTraffic = ConvertToReadableSize -size $sentBytes

    $receivedBandwidth = CalculateNetworkBandwidth -bytes $receivedBytes -interval $interval
    $sentBandwidth = CalculateNetworkBandwidth -bytes $sentBytes -interval $interval

    $receivedPercentage = [Math]::Round(($receivedBandwidth / 1000) * 100, 2)
    $sentPercentage = [Math]::Round(($sentBandwidth / 1000) * 100, 2)

    $output = "Traffic In: $receivedBandwidth Mb/s ($receivedPercentage %), Out: $sentBandwidth Mb/s ($sentPercentage %)"

    Write-Host $output

    if ($receivedPercentage -ge $criticalThreshold -or $sentPercentage -ge $criticalThreshold) {
        exit 2  # Critical state
    } elseif ($receivedPercentage -ge $warningThreshold -or $sentPercentage -ge $warningThreshold) {
        exit 1  # Warning state
    } else {
        exit 0  # OK state
    }
} else {
    Write-Host "Network interface '$interfaceName' not found. Using active interface: $activeInterface"
    $interfaceName = $activeInterface
    exit 2  # Critical state
}
