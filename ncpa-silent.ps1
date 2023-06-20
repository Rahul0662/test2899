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
