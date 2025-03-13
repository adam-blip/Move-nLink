<#
.SYNOPSIS
    Moves directories from source to target location while creating junction links.

.DESCRIPTION
    Move'nLink is a PowerShell utility that helps reorganize your file system by moving 
    directories to a new location while maintaining functionality for applications that 
    expect the directories to be in their original location.

    The script moves each subdirectory from the source location to the target location,
    then creates a junction link at the original location pointing to the new location.

.PARAMETER SourceDir
    The directory containing the folders you want to move.

.PARAMETER TargetDir
    The destination directory where folders will be moved to.

.EXAMPLE
    .\Move-nLink.ps1 -SourceDir "C:\Users\YourName\AppData\Local\GameData" -TargetDir "D:\GameData"
    
    Moves all subdirectories from C:\Users\YourName\AppData\Local\GameData to D:\GameData
    and creates junction links in the original location.

.NOTES
    File Name      : Move-nLink.ps1
    Author         : Your Name
    Prerequisite   : PowerShell 5.1 or later
    License        : MIT
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="The source directory containing folders to move")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceDir,
    
    [Parameter(Mandatory=$true, Position=1, HelpMessage="The target directory where folders will be moved to")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetDir
)

#region Functions

# Check if running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Log messages with timestamp and color-coding
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    switch ($Type) {
        "Info"    { Write-Host $logMessage -ForegroundColor Cyan }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        "Error"   { Write-Host $logMessage -ForegroundColor Red }
        "Success" { Write-Host $logMessage -ForegroundColor Green }
    }
}

#endregion Functions

#region Main Script

try {
    # Check for administrator privileges
    if (-not (Test-Admin)) {
        Write-Log "This script requires administrator privileges to create junction links." -Type "Warning"
        Write-Log "Attempting to restart with elevated permissions..." -Type "Info"
        
        try {
            # Restart script with admin privileges
            $scriptPath = $MyInvocation.MyCommand.Definition
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -SourceDir `"$SourceDir`" -TargetDir `"$TargetDir`"" -Verb RunAs
        }
        catch {
            Write-Log "Failed to restart with administrator privileges: $_" -Type "Error"
            exit 1
        }
        
        # Exit current non-elevated instance
        exit 0
    }

    # Ensure source directory exists
    if (-not (Test-Path -Path $SourceDir -PathType Container)) {
        Write-Log "Source directory does not exist: $SourceDir" -Type "Error"
        exit 1
    }

    # Validate source directory is absolute path
    if (-not [System.IO.Path]::IsPathRooted($SourceDir)) {
        $SourceDir = Resolve-Path $SourceDir
        Write-Log "Source directory converted to absolute path: $SourceDir" -Type "Info"
    }

    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetDir -PathType Container)) {
        Write-Log "Target directory does not exist. Creating: $TargetDir" -Type "Info"
        try {
            New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
            Write-Log "Created target directory successfully." -Type "Success"
        }
        catch {
            Write-Log "Failed to create target directory: $_" -Type "Error"
            exit 1
        }
    }

    # Validate target directory is absolute path
    if (-not [System.IO.Path]::IsPathRooted($TargetDir)) {
        $TargetDir = Resolve-Path $TargetDir
        Write-Log "Target directory converted to absolute path: $TargetDir" -Type "Info"
    }
    
    # Get all subdirectories in the source directory
    Write-Log "Scanning for subdirectories in: $SourceDir" -Type "Info"
    $directories = Get-ChildItem -Path $SourceDir -Directory
    
    if ($directories.Count -eq 0) {
        Write-Log "No subdirectories found in source directory." -Type "Warning"
        exit 0
    }
    
    Write-Log "Found $($directories.Count) subdirectories to process." -Type "Info"
    
    # Initialize counters
    $successCount = 0
    $skipCount = 0
    $errorCount = 0
    
    # Process each directory
    foreach ($dir in $directories) {
        $sourcePath = $dir.FullName
        $dirName = $dir.Name
        $targetPath = Join-Path -Path $TargetDir -ChildPath $dirName
        
        Write-Log "Processing directory: $dirName" -Type "Info"
        
        # Check if target already exists
        if (Test-Path -Path $targetPath) {
            Write-Log "Target directory already exists: $targetPath - Skipping" -Type "Warning"
            $skipCount++
            continue
        }
        
        try {
            # Move the directory to the target
            Write-Log "Moving $sourcePath to $targetPath" -Type "Info"
            Move-Item -Path $sourcePath -Destination $targetPath -ErrorAction Stop
            
            # Create junction link
            Write-Log "Creating junction link from $sourcePath to $targetPath" -Type "Info"
            $mkLinkResult = cmd.exe /c mklink /J "$sourcePath" "$targetPath" 2>&1
            
            # Verify the junction was created successfully
            if (Test-Path -Path $sourcePath -PathType Container) {
                Write-Log "Successfully processed: $dirName" -Type "Success"
                $successCount++
            }
            else {
                Write-Log "Junction link creation may have failed: $mkLinkResult" -Type "Error"
                $errorCount++
            }
        }
        catch {
            Write-Log "Error processing $dirName`: $_" -Type "Error"
            $errorCount++
            
            # Attempt to recover by moving the directory back if target exists
            if (-not (Test-Path -Path $sourcePath) -and (Test-Path -Path $targetPath)) {
                try {
                    Write-Log "Attempting to restore directory to original location..." -Type "Info"
                    Move-Item -Path $targetPath -Destination $sourcePath -ErrorAction Stop
                    Write-Log "Directory restored to original location." -Type "Success"
                }
                catch {
                    Write-Log "Failed to restore directory: $_" -Type "Error"
                }
            }
        }
    }
    
    # Summary report
    Write-Log "`nOperation completed with: $successCount successful, $skipCount skipped, $errorCount errors" -Type $(if ($errorCount -gt 0) { "Warning" } else { "Success" })
}
catch {
    Write-Log "An unexpected error occurred: $_" -Type "Error"
    exit 1
}

#endregion Main Script