

# Define the paths
$ncpaInstallDir = "C:\Program Files (x86)\Nagios\NCPA"
$ncpaConfigDir = Join-Path $ncpaInstallDir "etc"
$ncpaConfigFile = Join-Path $ncpaConfigDir "ncpa.cfg"
$ncpaConfigBackupFile = Join-Path $ncpaConfigDir "ncpa.cfg-bkp"
$ncpaPluginsDir = Join-Path $ncpaInstallDir "plugins"
$tempBackupDir = "C:\Temp\NCPABackup"

# Create a temporary backup directory
New-Item -ItemType Directory -Path $tempBackupDir -Force | Out-Null

# Take a backup of the existing NCPA config file
if (Test-Path $ncpaConfigFile) {
    Copy-Item -Path $ncpaConfigFile -Destination $tempBackupDir -Force
    Write-Host "Backed up existing NCPA configuration file."
}

# Take a backup of the existing NCPA plugins folder
if (Test-Path $ncpaPluginsDir) {
    Copy-Item -Path $ncpaPluginsDir -Destination $tempBackupDir -Recurse -Force
    Write-Host "Backed up existing NCPA plugins folder."
}

# Uninstall the older version of NCPA
Write-Host "Uninstalling the older version of NCPA..."
$uninstallResult = Start-Process -FilePath "C:\Program Files (x86)\Nagios\NCPA\uninstall.exe" -ArgumentList "/S" -Wait -PassThru

if ($uninstallResult.ExitCode -eq 0) {
    Write-Host "Successfully uninstalled the older version of NCPA."
} else {
    Write-Host "Failed to uninstall the older version of NCPA. Exit code: $($uninstallResult.ExitCode)"
    Exit 1
}

# new agent path and file name
$installerFileName = "ncpa-2.4.0.exe"
# Define the path to the NCPA installer
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerPath = Join-Path $scriptDir $installerFileName

# Install the new version of NCPA silently
$status = "Installing the new version of NCPA..."
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

# Backup the new NCPA config file
if (Test-Path $ncpaConfigFile) {
    Copy-Item -Path $ncpaConfigFile -Destination $ncpaConfigBackupFile -Force
    Write-Host "Backed up the new NCPA configuration file."
}

# Restore the plugins folder and config file from the temporary backup directory
if (Test-Path $tempBackupDir) {
    Remove-Item -Path $ncpaPluginsDir -Recurse -Force
    Copy-Item -Path (Join-Path $tempBackupDir "plugins") -Destination $ncpaPluginsDir -Recurse -Force
    Copy-Item -Path (Join-Path $tempBackupDir "ncpa.cfg") -Destination $ncpaConfigDir -Force
    Write-Host "Restored plugins folder and NCPA configuration file."
}

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

# Remove the temporary backup directory
Remove-Item -Path $tempBackupDir -Recurse -Force
