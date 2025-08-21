# PowerShell script to install DOSBox and auto-configure for 8086 folder

# Variables
$installerUrl = "https://sourceforge.net/projects/dosbox/files/latest/download"
$installerPath = "$env:TEMP\dosbox-installer.exe"
$targetFolder = "C:\8086"

# Get current script directory and zip file path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$zipFile = Join-Path $scriptDir "8086.zip"

Write-Host "=== Downloading DOSBox Installer ==="
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "DOSBox installer downloaded to $installerPath"
} catch {
    Write-Host "❌ Failed to download DOSBox installer. Check your internet connection."
    exit
}

Write-Host "=== Installing DOSBox ==="
try {
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Write-Host "✅ DOSBox installed successfully."
} catch {
    Write-Host "❌ Installation failed. Please try manually."
    exit
}

Write-Host "=== Creating 8086 Folder ==="
if (!(Test-Path -Path $targetFolder)) {
    New-Item -Path $targetFolder -ItemType Directory | Out-Null
    Write-Host "Created folder $targetFolder"
} else {
    Write-Host "Folder $targetFolder already exists. Files may be overwritten."
}

Write-Host "=== Extracting ZIP Contents ==="
if (Test-Path -Path $zipFile) {
    Expand-Archive -Path $zipFile -DestinationPath $targetFolder -Force
    Write-Host "✅ Extracted $zipFile to $targetFolder"
} else {
    Write-Host "❌ ZIP file $zipFile not found in script directory ($scriptDir)"
    exit
}

Write-Host "=== Configuring DOSBox to Auto-Mount C:\8086 ==="

# DOSBox config file (location depends on Windows version)
$doscfg = "$env:USERPROFILE\AppData\Local\DOSBox\dosbox-0.74-3.conf"

if (Test-Path $doscfg) {
    # Add mount command at the end of [autoexec] section
    $cfgContent = Get-Content $doscfg
    if ($cfgContent -notmatch "mount c c:\\8086") {
        Add-Content $doscfg "`r`n[autoexec]`r`nmount c c:\8086`r`nc:`r`n"
        Write-Host "✅ DOSBox config updated to auto-mount C:\8086"
    } else {
        Write-Host "DOSBox already configured to mount C:\8086"
    }
} else {
    Write-Host "⚠️ Could not find DOSBox config file at $doscfg"
    Write-Host "You may need to run DOSBox once so it generates the config file."
}

Write-Host "=== Setup Completed Successfully ==="
