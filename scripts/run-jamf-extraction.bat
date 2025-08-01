@echo off
REM ============================================================================
REM JAMF Pro Data Extraction Wrapper Script
REM ============================================================================
REM This batch file is designed to be called from Hitachi PDI data pipeline
REM It executes the PowerShell script with proper error handling and logging
REM ============================================================================

setlocal enabledelayedexpansion

REM Set script directory and paths
set "SCRIPT_DIR=%~dp0"
set "BASE_DIR=C:\backend\data-integration4\scripts\jamf"
set "PS_SCRIPT=%BASE_DIR%\scripts\Get-JamfData.ps1"
set "CONFIG_FILE=%BASE_DIR%\config.json"
set "LOG_DIR=%BASE_DIR%\logs"
set "DATA_DIR=%BASE_DIR%\data"

REM Create timestamp for this execution
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=%datetime:~0,8%_%datetime:~8,6%"
set "BATCH_LOG=%LOG_DIR%\batch_execution_%TIMESTAMP%.log"

REM Ensure directories exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

REM Initialize batch log
echo ============================================================================ > "%BATCH_LOG%"
echo JAMF Pro Data Extraction - Batch Wrapper Execution Log >> "%BATCH_LOG%"
echo Start Time: %date% %time% >> "%BATCH_LOG%"
echo ============================================================================ >> "%BATCH_LOG%"
echo. >> "%BATCH_LOG%"

REM Log environment information
echo Environment Information: >> "%BATCH_LOG%"
echo - Script Directory: %SCRIPT_DIR% >> "%BATCH_LOG%"
echo - Base Directory: %BASE_DIR% >> "%BATCH_LOG%"
echo - PowerShell Script: %PS_SCRIPT% >> "%BATCH_LOG%"
echo - Config File: %CONFIG_FILE% >> "%BATCH_LOG%"
echo - Log Directory: %LOG_DIR% >> "%BATCH_LOG%"
echo - Data Directory: %DATA_DIR% >> "%BATCH_LOG%"
echo - Batch Log: %BATCH_LOG% >> "%BATCH_LOG%"
echo. >> "%BATCH_LOG%"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo ERROR: PowerShell script not found at: %PS_SCRIPT% >> "%BATCH_LOG%"
    echo ERROR: PowerShell script not found at: %PS_SCRIPT%
    exit /b 1
)

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo ERROR: Configuration file not found at: %CONFIG_FILE% >> "%BATCH_LOG%"
    echo ERROR: Configuration file not found at: %CONFIG_FILE%
    exit /b 1
)

REM Log start of PowerShell execution
echo Starting PowerShell script execution... >> "%BATCH_LOG%"
echo Command: powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -ConfigPath "%CONFIG_FILE%" >> "%BATCH_LOG%"
echo. >> "%BATCH_LOG%"

REM Execute PowerShell script with error capture
echo Executing JAMF Pro data extraction...
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%PS_SCRIPT%" -ConfigPath "%CONFIG_FILE%" 2>&1

REM Capture PowerShell exit code
set "PS_EXIT_CODE=%ERRORLEVEL%"

REM Log PowerShell execution result
echo. >> "%BATCH_LOG%"
echo PowerShell execution completed with exit code: %PS_EXIT_CODE% >> "%BATCH_LOG%"

REM Handle different exit codes
if %PS_EXIT_CODE% equ 0 (
    echo SUCCESS: JAMF data extraction completed successfully >> "%BATCH_LOG%"
    echo SUCCESS: JAMF data extraction completed successfully
    
    REM Check if output files were created
    echo Checking for output files... >> "%BATCH_LOG%"
    dir "%DATA_DIR%\jamf_computers_inventory_*.json" /b 2>nul | findstr . >nul
    if !ERRORLEVEL! equ 0 (
        echo - JSON files found in data directory >> "%BATCH_LOG%"
    ) else (
        echo - WARNING: No JSON files found in data directory >> "%BATCH_LOG%"
    )
    
    dir "%DATA_DIR%\jamf_computers_inventory_*.csv" /b 2>nul | findstr . >nul
    if !ERRORLEVEL! equ 0 (
        echo - CSV files found in data directory >> "%BATCH_LOG%"
    ) else (
        echo - WARNING: No CSV files found in data directory >> "%BATCH_LOG%"
    )
    
) else if %PS_EXIT_CODE% equ 1 (
    echo ERROR: Configuration or authentication error >> "%BATCH_LOG%"
    echo ERROR: Configuration or authentication error
) else if %PS_EXIT_CODE% equ 2 (
    echo ERROR: Network connectivity error >> "%BATCH_LOG%"
    echo ERROR: Network connectivity error
) else if %PS_EXIT_CODE% equ 3 (
    echo ERROR: Data extraction error >> "%BATCH_LOG%"
    echo ERROR: Data extraction error
) else (
    echo ERROR: Unknown error occurred (Exit Code: %PS_EXIT_CODE%) >> "%BATCH_LOG%"
    echo ERROR: Unknown error occurred (Exit Code: %PS_EXIT_CODE%)
)

REM Log completion
echo. >> "%BATCH_LOG%"
echo ============================================================================ >> "%BATCH_LOG%"
echo End Time: %date% %time% >> "%BATCH_LOG%"
echo Final Exit Code: %PS_EXIT_CODE% >> "%BATCH_LOG%"
echo ============================================================================ >> "%BATCH_LOG%"

REM Display final status for PDI
echo.
echo ============================================================================
echo JAMF Pro Data Extraction - Batch Execution Summary
echo ============================================================================
echo Exit Code: %PS_EXIT_CODE%
echo Log File: %BATCH_LOG%
if exist "%DATA_DIR%\jamf_computers_inventory_*.json" echo Data Files: Available in %DATA_DIR%
echo ============================================================================

REM Exit with the same code as PowerShell script for PDI error handling
exit /b %PS_EXIT_CODE%