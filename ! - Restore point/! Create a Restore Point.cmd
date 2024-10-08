mode con: cols=75 lines=28
@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit 

<#
.SYNOPSIS
Script to create or restore a system restore point.

.DESCRIPTION
This script checks if it is running with administrative privileges, then prompts the user to create or restore a system restore point. The script uses PowerShell cmdlets for creating and restoring restore points.

.NOTES
Author: Ibrahim
Website: https://ibrpride.com
Script Version: 1.2
Last Updated: July 2024
#>

# Check if the script is running as an admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch as an administrator
    Start-Process powershell.exe -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $MyInvocation.MyCommand.Definition) -Verb RunAs
    exit
}

# Set console window properties for administrator session
$Host.UI.RawUI.WindowTitle = "Restore Point Management | @IBRHUB"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ErrorForegroundColor = "Red"
$Host.PrivateData.WarningForegroundColor = "Yellow"
$Host.PrivateData.DebugForegroundColor = "Cyan"
$Host.PrivateData.VerboseForegroundColor = "Green"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"

# Set Console Opacity Transparent
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class ConsoleOpacity {
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);

    private const uint LWA_ALPHA = 0x00000002;

    public static void SetOpacity(byte opacity) {
        IntPtr hwnd = GetConsoleWindow();
        if (hwnd == IntPtr.Zero) {
            throw new InvalidOperationException("Failed to get console window handle.");
        }
        bool result = SetLayeredWindowAttributes(hwnd, 0, opacity, LWA_ALPHA);
        if (!result) {
            throw new InvalidOperationException("Failed to set window opacity.");
        }
    }
}
"@

try {
    # Set opacity (0-255, where 255 is fully opaque and 0 is fully transparent)
    [ConsoleOpacity]::SetOpacity(230)
    Write-Host "Console opacity set successfully." -ForegroundColor Green
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

# Clear the console screen
Clear-Host

# Function to check if the script is running as an administrator
function Check-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script must be run as Administrator."
        pause
        exit 1
    }
}

# Function to create a restore point
function Create-RestorePoint {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestoreName
    )
    Write-Host "Creating Restore Point with name: $RestoreName ..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Force
    if ($?) {
        Checkpoint-Computer -Description $RestoreName -RestorePointType "MODIFY_SETTINGS"
        if ($?) {
            Clear-Host
            Write-Host ""
            Write-Host "Restore point created successfully." -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "Failed to create restore point." -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to set registry key." -ForegroundColor Red
    }
    pause
}

# Function to restore a backup from a selected restore point
function Restore-Backup {
    $restorePoints = Get-ComputerRestorePoint | Select-Object -Property SequenceNumber, Description, CreationTime
    if ($restorePoints) {
        Write-Host "Available restore points:" -ForegroundColor Green
        $restorePoints | ForEach-Object { Write-Host "$($_.SequenceNumber) - $($_.Description) - $($_.CreationTime)" }
        $sequenceNumber = Read-Host "Enter the Sequence Number of the restore point you want to restore"
        $restorePoint = $restorePoints | Where-Object { $_.SequenceNumber -eq [int]$sequenceNumber }
        if ($restorePoint) {
            Restore-Computer -RestorePoint $restorePoint.SequenceNumber
            if ($?) {
                Write-Host "Backup restored successfully." -ForegroundColor Green
            } else {
                Write-Host "Failed to restore the backup." -ForegroundColor Red
            }
        } else {
            Write-Host "Invalid Sequence Number. Restore point not found." -ForegroundColor Red
        }
    } else {
        Write-Host "No restore points available." -ForegroundColor Red
    }
    pause
}

# Main script execution
Check-Admin
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "                            Select an option:" -ForegroundColor Yellow
Write-Host ""
Write-Host "            ___________________________________________________ "
Write-Host ""
Write-Host "                [1] Create a Restore Point"-ForegroundColor Green
Write-Host "                [2] Restore from an available restore point" -ForegroundColor Cyan
Write-Host "                [3] Exit" -ForegroundColor Red
Write-Host ""
Write-Host "            ___________________________________________________ "
Write-Host ""
$choice = Read-Host "               Enter a menu option in the Keyboard [1,2,3]"
Write-Host ""
Write-Host ""
switch ($choice) {
    1 {
        $restoreName = Read-Host "                Enter the name for the Restore Point"
        Create-RestorePoint -RestoreName $restoreName
    }
    2 {
        Restore-Backup
    }
    3 {
        exit
    }
    default {
        Write-Host "Invalid choice. Please enter 1, 2, or 3."
        pause
    }
}

# Pause the script to view the output
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
