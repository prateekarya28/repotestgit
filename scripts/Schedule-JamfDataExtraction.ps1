<#
.SYNOPSIS
    Schedule JAMF Pro Data Extraction using Windows Task Scheduler
    
.DESCRIPTION
    This script creates a scheduled task in Windows Task Scheduler to run the JAMF Pro data extraction script at regular intervals.
    
.PARAMETER TaskName
    Name of the scheduled task
    
.PARAMETER ScriptPath
    Path to the Get-JamfData.ps1 script
    
.PARAMETER Schedule
    Schedule frequency (Daily, Weekly, Monthly, Hourly)
    
.PARAMETER StartTime
    Time to start the scheduled task (format: HH:mm)
    
.PARAMETER RunAsUser
    User account to run the task as (default: current user)
    
.EXAMPLE
    .\Schedule-JamfDataExtraction.ps1 -TaskName "JAMF Data Extract" -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Daily" -StartTime "08:00"
    
.NOTES
    Requires Administrator privileges to create scheduled tasks
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "JAMF Pro Data Extraction",
    
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly", "Hourly")]
    [string]$Schedule = "Daily",
    
    [Parameter(Mandatory = $false)]
    [string]$StartTime = "08:00",
    
    [Parameter(Mandatory = $false)]
    [string]$RunAsUser = $env:USERNAME
)

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-JamfScheduledTask {
    param(
        [string]$Name,
        [string]$Script,
        [string]$Frequency,
        [string]$Time,
        [string]$User
    )
    
    try {
        # Check if script exists
        if (!(Test-Path $Script)) {
            throw "Script file not found: $Script"
        }
        
        # Convert script path to absolute path
        $absoluteScriptPath = (Resolve-Path $Script).Path
        
        # Create the action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$absoluteScriptPath`""
        
        # Create the trigger based on schedule
        switch ($Frequency) {
            "Hourly" {
                $trigger = New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365)
            }
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At $Time
            }
            "Weekly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Monday -At $Time
            }
            "Monthly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At $Time
            }
        }
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Create the principal (user context)
        $principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Scheduled task '$Name' already exists. Updating..." -ForegroundColor Yellow
            Set-ScheduledTask -TaskName $Name -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        } else {
            # Register the scheduled task
            Register-ScheduledTask -TaskName $Name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated JAMF Pro data extraction task"
        }
        
        Write-Host "Scheduled task '$Name' created/updated successfully!" -ForegroundColor Green
        Write-Host "Schedule: $Frequency at $Time" -ForegroundColor Green
        Write-Host "Script: $absoluteScriptPath" -ForegroundColor Green
        Write-Host "Run as: $User" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-TaskInformation {
    param([string]$Name)
    
    try {
        $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
        $taskInfo = Get-ScheduledTaskInfo -TaskName $Name
        
        Write-Host "`nScheduled Task Information:" -ForegroundColor Cyan
        Write-Host "Name: $($task.TaskName)" -ForegroundColor White
        Write-Host "State: $($task.State)" -ForegroundColor White
        Write-Host "Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "Next Run Time: $($taskInfo.NextRunTime)" -ForegroundColor White
        Write-Host "Last Task Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
        
        # Show task management commands
        Write-Host "`nTask Management Commands:" -ForegroundColor Cyan
        Write-Host "Start task manually: Start-ScheduledTask -TaskName '$Name'" -ForegroundColor Yellow
        Write-Host "Stop task: Stop-ScheduledTask -TaskName '$Name'" -ForegroundColor Yellow
        Write-Host "Disable task: Disable-ScheduledTask -TaskName '$Name'" -ForegroundColor Yellow
        Write-Host "Enable task: Enable-ScheduledTask -TaskName '$Name'" -ForegroundColor Yellow
        Write-Host "Remove task: Unregister-ScheduledTask -TaskName '$Name' -Confirm:`$false" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Task information not available: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Write-Host "JAMF Pro Data Extraction - Task Scheduler Setup" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    
    # Check for administrator privileges
    if (!(Test-Administrator)) {
        Write-Host "Warning: This script should be run as Administrator to create scheduled tasks." -ForegroundColor Yellow
        Write-Host "Some operations may fail without proper privileges." -ForegroundColor Yellow
    }
    
    # Validate script path
    if (!(Test-Path $ScriptPath)) {
        Write-Host "Error: Script file not found at: $ScriptPath" -ForegroundColor Red
        Write-Host "Please provide a valid path to the Get-JamfData.ps1 script." -ForegroundColor Red
        exit 1
    }
    
    # Create the scheduled task
    Write-Host "Creating scheduled task..." -ForegroundColor Green
    $success = New-JamfScheduledTask -Name $TaskName -Script $ScriptPath -Frequency $Schedule -Time $StartTime -User $RunAsUser
    
    if ($success) {
        Show-TaskInformation -Name $TaskName
        
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Ensure the JAMF Pro API credentials are properly configured in config.json" -ForegroundColor White
        Write-Host "2. Test the script manually before relying on the scheduled task" -ForegroundColor White
        Write-Host "3. Monitor the task execution and logs in the output directory" -ForegroundColor White
        Write-Host "4. Check Windows Event Viewer for any task scheduler issues" -ForegroundColor White
    } else {
        Write-Host "Failed to create the scheduled task. Please check the error messages above." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}