# PowerShell script to install DOSBox and auto-configure for 8086 folder

# Variables
$targetFolder = "C:\8086"

# Get current script directory and file paths
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installer   = Join-Path $scriptDir "DOSBox0.74-win32-installer.exe"
$zipFile     = Join-Path $scriptDir "8086_Assembler.zip"

Write-Host "=== Checking for DOSBox Installer ==="
if (!(Test-Path $installer)) {
    Write-Host "❌ DOSBox installer not found at $installer"
    exit
}

Write-Host "=== Installing DOSBox ==="
try {
    Start-Process -FilePath $installer -ArgumentList "/S" -Wait
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

Write-Host "=== Generating DOSBox config file ==="

# Try standard install locations
$dosboxExe = "${env:ProgramFiles(x86)}\DOSBox-0.74\DOSBox.exe"
if (!(Test-Path $dosboxExe)) {
    $dosboxExe = "${env:ProgramFiles}\DOSBox-0.74\DOSBox.exe"
}

# Target config path
$doscfg = "$env:USERPROFILE\AppData\Local\DOSBox\dosbox-0.74.conf"

if (Test-Path $dosboxExe) {
    # Force DOSBox to write a config file
    Start-Process -FilePath $dosboxExe -ArgumentList " -noconsole -exit -c `"config -writeconf $doscfg`"" -Wait
    Write-Host "✅ Config file generated at $doscfg"
} else {
    Write-Host "❌ DOSBox executable not found. Check installation path."
}


Write-Host "=== Configuring DOSBox to Auto-Mount C:\8086 ==="
# DOSBox config file (location depends on Windows version and version of DOSBox)

if (Test-Path $doscfg) {
    # Add mount command at the end of [autoexec] section only if not already there
    $cfgContent = Get-Content $doscfg
    if ($cfgContent -notmatch "mount c c:\\8086") {
        Add-Content $doscfg "`r`n[autoexec]`r`nmount c c:\8086`r`nc:`r`n"
        Write-Host "✅ DOSBox config updated to auto-mount C:\8086"
    } else {
        Write-Host "DOSBox already configured to mount C:\8086"
    }
} else {
    Write-Host "⚠️ Could not find DOSBox config file at $doscfg"
    Write-Host "Try running DOSBox manually once if the config wasn’t created."
}

Write-Host "=== Setup Completed Successfully ==="
