<#
.SYNOPSIS
    Test JAMF Pro API Connection and Credentials
    
.DESCRIPTION
    This script tests the connection to JAMF Pro API and validates the provided credentials.
    It's useful for troubleshooting before running the main data extraction script.
    
.PARAMETER ConfigPath
    Path to the configuration file containing API credentials
    
.EXAMPLE
    .\Test-JamfConnection.ps1 -ConfigPath ".\config.json"
    
.NOTES
    Author: System Administrator
    Version: 1.0
    Requires PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\config.json"
)

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Success,
        [string]$Message = ""
    )
    
    $status = if ($Success) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
}

function Test-ConfigurationFile {
    param([string]$Path)
    
    try {
        if (!(Test-Path $Path)) {
            Write-TestResult -Test "Configuration File Exists" -Success $false -Message "File not found: $Path"
            return $null
        }
        
        Write-TestResult -Test "Configuration File Exists" -Success $true -Message $Path
        
        $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
        Write-TestResult -Test "Configuration File Valid JSON" -Success $true
        
        # Test required properties
        $requiredProps = @("jamf.baseUrl", "jamf.clientId", "jamf.clientSecret")
        foreach ($prop in $requiredProps) {
            $parts = $prop.Split('.')
            $value = $config
            foreach ($part in $parts) {
                $value = $value.$part
            }
            
            if ([string]::IsNullOrEmpty($value) -or $value -eq "YOUR_CLIENT_ID" -or $value -eq "YOUR_CLIENT_SECRET") {
                Write-TestResult -Test "Configuration Property: $prop" -Success $false -Message "Missing or default value"
                return $null
            } else {
                Write-TestResult -Test "Configuration Property: $prop" -Success $true -Message "Configured"
            }
        }
        
        return $config
    }
    catch {
        Write-TestResult -Test "Configuration File Valid JSON" -Success $false -Message $_.Exception.Message
        return $null
    }
}

function Test-NetworkConnectivity {
    param([string]$BaseUrl)
    
    try {
        $uri = [System.Uri]$BaseUrl
        $hostname = $uri.Host
        
        # Test DNS resolution
        try {
            $dns = Resolve-DnsName -Name $hostname -ErrorAction Stop
            Write-TestResult -Test "DNS Resolution" -Success $true -Message "Resolved to $($dns[0].IPAddress)"
        }
        catch {
            Write-TestResult -Test "DNS Resolution" -Success $false -Message $_.Exception.Message
            return $false
        }
        
        # Test HTTP connectivity
        try {
            $response = Invoke-WebRequest -Uri $BaseUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
            Write-TestResult -Test "HTTP Connectivity" -Success $true -Message "Status: $($response.StatusCode)"
        }
        catch {
            Write-TestResult -Test "HTTP Connectivity" -Success $false -Message $_.Exception.Message
            return $false
        }
        
        return $true
    }
    catch {
        Write-TestResult -Test "URL Validation" -Success $false -Message $_.Exception.Message
        return $false
    }
}

function Test-ApiAuthentication {
    param(
        [string]$BaseUrl,
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    try {
        $authUrl = "$BaseUrl/api/oauth/token"
        $authBody = @{
            client_id = $ClientId
            grant_type = "client_credentials"
            client_secret = $ClientSecret
        }
        
        Write-Host "Testing OAuth authentication..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $authBody -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        
        if ($response.access_token) {
            Write-TestResult -Test "OAuth Token Request" -Success $true -Message "Token obtained successfully"
            
            # Test token validation
            $testUrl = "$BaseUrl/api/v1/jamf-pro-information"
            $headers = @{
                "Authorization" = "Bearer $($response.access_token)"
                "Accept" = "application/json"
            }
            
            $jamfInfo = Invoke-RestMethod -Uri $testUrl -Method Get -Headers $headers -ErrorAction Stop
            Write-TestResult -Test "Token Validation" -Success $true -Message "JAMF Pro Version: $($jamfInfo.version)"
            
            return $response.access_token
        } else {
            Write-TestResult -Test "OAuth Token Request" -Success $false -Message "No access token in response"
            return $null
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response.StatusCode -eq 401) {
            $errorMsg = "Invalid credentials (401 Unauthorized)"
        }
        Write-TestResult -Test "OAuth Token Request" -Success $false -Message $errorMsg
        return $null
    }
}

function Test-ApiEndpoint {
    param(
        [string]$BaseUrl,
        [string]$AccessToken
    )
    
    try {
        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Accept" = "application/json"
        }
        
        # Test computers endpoint with minimal data
        $testUrl = "$BaseUrl/api/v1/computers-inventory?section=GENERAL&page=0&page-size=1"
        
        Write-Host "Testing computers inventory endpoint..." -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri $testUrl -Method Get -Headers $headers -ErrorAction Stop
        
        $computerCount = if ($response.totalCount) { $response.totalCount } else { "Unknown" }
        Write-TestResult -Test "Computers Inventory Endpoint" -Success $true -Message "Total computers: $computerCount"
        
        # Test available sections
        if ($response.results -and $response.results.Count -gt 0) {
            $computer = $response.results[0]
            $sections = @()
            if ($computer.general) { $sections += "GENERAL" }
            if ($computer.hardware) { $sections += "HARDWARE" }
            if ($computer.operatingSystem) { $sections += "OPERATING_SYSTEM" }
            if ($computer.userAndLocation) { $sections += "USER_AND_LOCATION" }
            if ($computer.softwareUpdates) { $sections += "SOFTWARE_UPDATES" }
            
            Write-Host "    Available sections: $($sections -join ', ')" -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response.StatusCode -eq 403) {
            $errorMsg = "Insufficient permissions (403 Forbidden)"
        }
        Write-TestResult -Test "Computers Inventory Endpoint" -Success $false -Message $errorMsg
        return $false
    }
}

function Test-OutputDirectory {
    param([string]$OutputPath = ".\data")
    
    try {
        if (!(Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-TestResult -Test "Output Directory Creation" -Success $true -Message "Created: $OutputPath"
        } else {
            Write-TestResult -Test "Output Directory Exists" -Success $true -Message $OutputPath
        }
        
        # Test write permissions
        $testFile = Join-Path $OutputPath "test_write.tmp"
        "test" | Out-File -FilePath $testFile -ErrorAction Stop
        Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        
        Write-TestResult -Test "Output Directory Write Access" -Success $true -Message "Write permissions confirmed"
        
        return $true
    }
    catch {
        Write-TestResult -Test "Output Directory Write Access" -Success $false -Message $_.Exception.Message
        return $false
    }
}

# Main execution
try {
    Write-Host "JAMF Pro API Connection Test" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    
    # Test 1: Configuration file
    Write-Host "1. Configuration Tests" -ForegroundColor White
    Write-Host "----------------------" -ForegroundColor White
    $config = Test-ConfigurationFile -Path $ConfigPath
    if (!$config) {
        Write-Host "`nConfiguration test failed. Please fix the issues above and try again." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Test 2: Network connectivity
    Write-Host "2. Network Connectivity Tests" -ForegroundColor White
    Write-Host "-----------------------------" -ForegroundColor White
    $networkOk = Test-NetworkConnectivity -BaseUrl $config.jamf.baseUrl
    if (!$networkOk) {
        Write-Host "`nNetwork connectivity test failed. Please check your network connection and JAMF Pro URL." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Test 3: Authentication
    Write-Host "3. Authentication Tests" -ForegroundColor White
    Write-Host "-----------------------" -ForegroundColor White
    $accessToken = Test-ApiAuthentication -BaseUrl $config.jamf.baseUrl -ClientId $config.jamf.clientId -ClientSecret $config.jamf.clientSecret
    if (!$accessToken) {
        Write-Host "`nAuthentication test failed. Please verify your Client ID and Client Secret." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Test 4: API endpoints
    Write-Host "4. API Endpoint Tests" -ForegroundColor White
    Write-Host "---------------------" -ForegroundColor White
    $apiOk = Test-ApiEndpoint -BaseUrl $config.jamf.baseUrl -AccessToken $accessToken
    if (!$apiOk) {
        Write-Host "`nAPI endpoint test failed. Please check your API permissions." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Test 5: Output directory
    Write-Host "5. Output Directory Tests" -ForegroundColor White
    Write-Host "-------------------------" -ForegroundColor White
    $outputOk = Test-OutputDirectory
    if (!$outputOk) {
        Write-Host "`nOutput directory test failed. Please check permissions." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Summary
    Write-Host "✅ All Tests Passed!" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your JAMF Pro API configuration is working correctly." -ForegroundColor Green
    Write-Host "You can now run the main data extraction script:" -ForegroundColor White
    Write-Host "  .\Get-JamfData.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To set up regular extraction, run:" -ForegroundColor White
    Write-Host "  .\Schedule-JamfDataExtraction.ps1 -ScriptPath 'C:\Scripts\Get-JamfData.ps1'" -ForegroundColor Yellow
}
catch {
    Write-Host "`nUnexpected error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}