# Stop the NSClient++ service
Stop-Service -Name "nscp" -Force

# Disable the NSClient++ service
Set-Service -Name "nscp" -StartupType Disabled

# Define the NCPA installer filename
$installerFileName = "ncpa-2.4.0.exe"

# Define the path to the NCPA installer
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerPath = Join-Path $scriptDir $installerFileName

# Install the NCPA agent silently
$status = "Installing NCPA..."
try {
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    $status += "Success"
}
catch {
    $status += "Error: $_.Exception.Message"
    Write-Host $status
    Exit 1  # Exit the script with a non-zero exit code
}
Write-Host $status

# Copy ncpa.cfg to NCPA etc directory
$ncpaConfigSourcePath = Join-Path $scriptDir "ncpa.cfg"
$ncpaConfigDestinationPath = "C:\Program Files (x86)\Nagios\NCPA\etc\ncpa.cfg"
$status = "Copying ncpa.cfg..."
try {
    Copy-Item -Path $ncpaConfigSourcePath -Destination $ncpaConfigDestinationPath -Force
    $status += "Success"
}
catch {
    $status += "Error: $_.Exception.Message"
    Write-Host $status
    Exit 1  # Exit the script with a non-zero exit code
}
Write-Host $status

# Copy network_monitor.ps1 to NCPA plugins directory
$networkMonitorSourcePath = Join-Path $scriptDir "network_monitor.ps1"
$networkMonitorDestinationPath = "C:\Program Files (x86)\Nagios\NCPA\plugins\network_monitor.ps1"
$status = "Copying network_monitor.ps1..."
try {
    Copy-Item -Path $networkMonitorSourcePath -Destination $networkMonitorDestinationPath -Force
    $status += "Success"
}
catch {
    $status += "Error: $_.Exception.Message"
    Write-Host $status
    Exit 1  # Exit the script with a non-zero exit code
}
Write-Host $status

# Start the NCPA agent service
$status = "Starting NCPA agent service..."
try {
    Start-Service -Name "ncpalistener"
    Stop-Service -Name "ncpapassive"
    $status += "Success"
}
catch {
    $status += "Error: $_.Exception.Message"
}
Write-Host $status
