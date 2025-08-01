@echo off
REM ============================================================================
REM Test Wrapper for JAMF Pro Data Extraction
REM ============================================================================
REM This script tests the batch wrapper functionality
REM ============================================================================

echo Testing JAMF Pro Data Extraction Wrapper...
echo.

REM Test 1: Check if wrapper script exists
if not exist "%~dp0run-jamf-extraction.bat" (
    echo ERROR: Wrapper script not found!
    pause
    exit /b 1
)

echo Found wrapper script: %~dp0run-jamf-extraction.bat
echo.

REM Test 2: Execute wrapper and capture result
echo Executing wrapper script...
echo ============================================================================
call "%~dp0run-jamf-extraction.bat"
set "WRAPPER_EXIT_CODE=%ERRORLEVEL%"

echo.
echo ============================================================================
echo Test Results:
echo - Wrapper Exit Code: %WRAPPER_EXIT_CODE%

if %WRAPPER_EXIT_CODE% equ 0 (
    echo - Status: SUCCESS
    echo - Data extraction completed successfully
) else if %WRAPPER_EXIT_CODE% equ 1 (
    echo - Status: CONFIGURATION ERROR
    echo - Check credentials and configuration
) else if %WRAPPER_EXIT_CODE% equ 2 (
    echo - Status: NETWORK ERROR  
    echo - Check connectivity and proxy settings
) else if %WRAPPER_EXIT_CODE% equ 3 (
    echo - Status: DATA EXTRACTION ERROR
    echo - Check API permissions and data availability
) else (
    echo - Status: UNKNOWN ERROR
    echo - Check logs for details
)

echo.
echo Test completed. Check logs for detailed information.
echo ============================================================================

pause
exit /b %WRAPPER_EXIT_CODE%