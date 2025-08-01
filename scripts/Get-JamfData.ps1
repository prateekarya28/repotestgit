<#
.SYNOPSIS
    JAMF Pro API Data Extraction Script
    
.DESCRIPTION
    This script extracts computer inventory data from JAMF Pro API using OAuth authentication.
    It supports multiple output formats (JSON, CSV) and includes comprehensive logging and error handling.
    
.PARAMETER ConfigPath
    Path to the configuration file containing API credentials and settings
    
.PARAMETER OutputFormat
    Output format for the data (JSON, CSV, or Both)
    
.PARAMETER OutputPath
    Directory path where the extracted data will be saved
    
.PARAMETER LogLevel
    Logging level (Info, Warning, Error, Debug)
    
.EXAMPLE
    .\Get-JamfData.ps1 -ConfigPath ".\config.json" -OutputFormat "Both" -OutputPath ".\data"
    
.NOTES
    Author: System Administrator
    Version: 1.0
    Requires PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\config.json",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Both")]
    [string]$OutputFormat = "Both",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "C:\backend\data-integration4\scripts\jamf\data",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error", "Debug")]
    [string]$LogLevel = "Info"
)

# Global variables
$Global:LogFile = ""
$Global:AccessToken = ""
$Global:Config = $null
$Global:ProxySettings = $null

#region Logging Functions
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    switch ($Level) {
        "Info"    { Write-Host $logEntry -ForegroundColor Green }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error"   { Write-Host $logEntry -ForegroundColor Red }
        "Debug"   { if ($LogLevel -eq "Debug") { Write-Host $logEntry -ForegroundColor Cyan } }
    }
    
    # Write to log file
    if ($Global:LogFile -and (Test-Path (Split-Path $Global:LogFile -Parent))) {
        Add-Content -Path $Global:LogFile -Value $logEntry
    }
}

function Initialize-Logging {
    param([string]$OutputDirectory)
    
    # Use config path if available, otherwise fall back to parameter
    $logDirectory = if ($Global:Config.output.logPath) { 
        $Global:Config.output.logPath 
    } else { 
        Join-Path $OutputDirectory "logs" 
    }
    
    if (!(Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Global:LogFile = Join-Path $logDirectory "jamf_extraction_$timestamp.log"
    
    Write-Log "Logging initialized. Log file: $Global:LogFile" -Level "Info"
}
#endregion

#region Configuration Functions
function Load-Configuration {
    param([string]$ConfigFilePath)
    
    try {
        if (!(Test-Path $ConfigFilePath)) {
            Write-Log "Configuration file not found at: $ConfigFilePath" -Level "Error"
            return $null
        }
        
        $configContent = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json
        Write-Log "Configuration loaded successfully from: $ConfigFilePath" -Level "Info"
        return $configContent
    }
    catch {
        Write-Log "Failed to load configuration: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

function New-DefaultConfiguration {
    param([string]$ConfigFilePath)
    
    $defaultConfig = @{
        jamf = @{
            baseUrl = "https://stmicroelectronics.jamfcloud.com"
            clientId = "YOUR_CLIENT_ID"
            clientSecret = "YOUR_CLIENT_SECRET"
            apiVersion = "v1"
        }
        extraction = @{
            sections = @("GENERAL", "USER_AND_LOCATION", "HARDWARE", "OPERATING_SYSTEM", "SOFTWARE_UPDATES")
            pageSize = 100
            sortBy = "general.name:asc"
            maxRetries = 3
            retryDelaySeconds = 5
        }
        output = @{
            timestampFormat = "yyyyMMdd_HHmmss"
            includeTimestampInFilename = $true
            compressOutput = $false
        }
    }
    
    try {
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFilePath -Encoding UTF8
        Write-Log "Default configuration file created at: $ConfigFilePath" -Level "Info"
        Write-Log "Please update the clientId and clientSecret in the configuration file." -Level "Warning"
        return $defaultConfig
    }
    catch {
        Write-Log "Failed to create default configuration file: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}
#endregion

#region Proxy Configuration Functions
function Initialize-ProxySettings {
    param($Config)
    
    try {
        if ($Config.proxy.enabled -eq $true) {
            Write-Log "Configuring proxy settings..." -Level "Info"
            
            # Import CredentialManager module
            try {
                Import-Module CredentialManager -ErrorAction Stop
                Write-Log "CredentialManager module imported successfully" -Level "Debug"
            }
            catch {
                Write-Log "Warning: Failed to import CredentialManager module: $($_.Exception.Message)" -Level "Warning"
                Write-Log "Proxy will use default credentials" -Level "Warning"
            }
            
            $proxyUrl = $Config.proxy.url
            $credentialTarget = $Config.proxy.credentialTarget
            
            # Get stored credentials if specified
            $proxyCredential = $null
            if ($credentialTarget -and $credentialTarget -ne "****") {
                try {
                    $proxyCredential = Get-StoredCredential -Target $credentialTarget
                    if ($proxyCredential) {
                        Write-Log "Proxy credentials loaded from credential store: $credentialTarget" -Level "Info"
                    } else {
                        Write-Log "Warning: Could not retrieve proxy credentials from store for target: $credentialTarget" -Level "Warning"
                    }
                }
                catch {
                    Write-Log "Warning: Failed to load proxy credentials from $credentialTarget : $($_.Exception.Message)" -Level "Warning"
                }
            }
            
            $Global:ProxySettings = @{
                Url = $proxyUrl
                Credential = $proxyCredential
                UseDefaultCredentials = $proxyCredential -eq $null
            }
            
            Write-Log "Proxy configured: $proxyUrl" -Level "Info"
            if ($proxyCredential) {
                Write-Log "Using stored credentials for proxy authentication" -Level "Info"
            } else {
                Write-Log "Using default credentials for proxy authentication" -Level "Info"
            }
        } else {
            Write-Log "Proxy disabled in configuration" -Level "Info"
            $Global:ProxySettings = $null
        }
    }
    catch {
        Write-Log "Failed to configure proxy settings: $($_.Exception.Message)" -Level "Error"
        $Global:ProxySettings = $null
    }
}

function Get-WebRequestParams {
    param(
        [hashtable]$BaseParams = @{}
    )
    
    $params = $BaseParams.Clone()
    
    if ($Global:ProxySettings) {
        $params.Proxy = $Global:ProxySettings.Url
        
        if ($Global:ProxySettings.Credential) {
            $params.ProxyCredential = $Global:ProxySettings.Credential
        } elseif ($Global:ProxySettings.UseDefaultCredentials) {
            $params.ProxyUseDefaultCredentials = $true
        }
        
        Write-Log "Using proxy for web request: $($Global:ProxySettings.Url)" -Level "Debug"
    }
    
    return $params
}
#endregion

#region Authentication Functions
function Get-AccessToken {
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
        
        Write-Log "Requesting access token from JAMF Pro..." -Level "Info"
        
        $webParams = Get-WebRequestParams -BaseParams @{
            Uri = $authUrl
            Method = "Post"
            Body = $authBody
            ContentType = "application/x-www-form-urlencoded"
        }
        
        $response = Invoke-RestMethod @webParams
        
        if ($response.access_token) {
            Write-Log "Access token obtained successfully" -Level "Info"
            return $response.access_token
        } else {
            Write-Log "No access token in response" -Level "Error"
            return $null
        }
    }
    catch {
        Write-Log "Failed to obtain access token: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

function Test-AccessToken {
    param(
        [string]$BaseUrl,
        [string]$AccessToken
    )
    
    try {
        $testUrl = "$BaseUrl/api/v1/jamf-pro-information"
        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Accept" = "application/json"
        }
        
        $webParams = Get-WebRequestParams -BaseParams @{
            Uri = $testUrl
            Method = "Get"
            Headers = $headers
        }
        
        $response = Invoke-RestMethod @webParams
        Write-Log "Access token validation successful" -Level "Info"
        return $true
    }
    catch {
        Write-Log "Access token validation failed: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}
#endregion

#region Data Extraction Functions
function Get-ComputersInventory {
    param(
        [string]$BaseUrl,
        [string]$AccessToken,
        [array]$Sections,
        [int]$PageSize,
        [string]$SortBy,
        [int]$MaxRetries,
        [int]$RetryDelay
    )
    
    $allComputers = @()
    $page = 0
    $hasMoreData = $true
    
    $headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Accept" = "application/json"
    }
    
    while ($hasMoreData) {
        $sectionsParam = ($Sections | ForEach-Object { "section=$_" }) -join "&"
        $url = "$BaseUrl/api/v1/computers-inventory?$sectionsParam&page=$page&page-size=$PageSize&sort=$SortBy"
        
        Write-Log "Fetching page $($page + 1) of computer inventory data..." -Level "Info"
        
        $retryCount = 0
        $success = $false
        
        while ($retryCount -lt $MaxRetries -and !$success) {
            try {
                $webParams = Get-WebRequestParams -BaseParams @{
                    Uri = $url
                    Method = "Get"
                    Headers = $headers
                }
                
                $response = Invoke-RestMethod @webParams
                $success = $true
                
                if ($response.results -and $response.results.Count -gt 0) {
                    $allComputers += $response.results
                    Write-Log "Retrieved $($response.results.Count) computers from page $($page + 1)" -Level "Info"
                    
                    # Check if there are more pages
                    if ($response.results.Count -lt $PageSize) {
                        $hasMoreData = $false
                        Write-Log "Reached last page of data" -Level "Info"
                    } else {
                        $page++
                    }
                } else {
                    $hasMoreData = $false
                    Write-Log "No more data available" -Level "Info"
                }
            }
            catch {
                $retryCount++
                Write-Log "Attempt $retryCount failed: $($_.Exception.Message)" -Level "Warning"
                
                if ($retryCount -lt $MaxRetries) {
                    Write-Log "Retrying in $RetryDelay seconds..." -Level "Info"
                    Start-Sleep -Seconds $RetryDelay
                } else {
                    Write-Log "Max retries reached. Stopping data extraction." -Level "Error"
                    throw $_
                }
            }
        }
    }
    
    Write-Log "Total computers retrieved: $($allComputers.Count)" -Level "Info"
    return $allComputers
}
#endregion

#region Data Export Functions
function Export-ToJson {
    param(
        [array]$Data,
        [string]$OutputDirectory,
        [bool]$IncludeTimestamp
    )
    
    try {
        # Use config data path if available, otherwise fall back to parameter
        $dataDirectory = if ($Global:Config.output.dataPath) { 
            $Global:Config.output.dataPath 
        } else { 
            $OutputDirectory 
        }
        
        # Ensure data directory exists
        if (!(Test-Path $dataDirectory)) {
            New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null
        }
        
        $timestamp = if ($IncludeTimestamp) { "_$(Get-Date -Format 'yyyyMMdd_HHmmss')" } else { "" }
        $fileName = "jamf_computers_inventory$timestamp.json"
        $filePath = Join-Path $dataDirectory $fileName
        
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8
        Write-Log "JSON data exported to: $filePath" -Level "Info"
        return $filePath
    }
    catch {
        Write-Log "Failed to export JSON data: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

function Export-ToCsv {
    param(
        [array]$Data,
        [string]$OutputDirectory,
        [bool]$IncludeTimestamp
    )
    
    try {
        # Use config data path if available, otherwise fall back to parameter
        $dataDirectory = if ($Global:Config.output.dataPath) { 
            $Global:Config.output.dataPath 
        } else { 
            $OutputDirectory 
        }
        
        # Ensure data directory exists
        if (!(Test-Path $dataDirectory)) {
            New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null
        }
        
        $timestamp = if ($IncludeTimestamp) { "_$(Get-Date -Format 'yyyyMMdd_HHmmss')" } else { "" }
        
        # Flatten the complex object structure for CSV export
        $flattenedData = $Data | ForEach-Object {
            $computer = $_
            [PSCustomObject]@{
                ComputerId = $computer.general.id
                ComputerName = $computer.general.name
                SerialNumber = $computer.general.serialNumber
                AssetTag = $computer.general.assetTag
                Model = $computer.hardware.model
                ModelFamily = $computer.hardware.modelFamily
                Processor = $computer.hardware.processorType
                ProcessorSpeed = $computer.hardware.processorSpeedMhz
                TotalRAM = $computer.hardware.totalRamMegabytes
                OSName = $computer.operatingSystem.name
                OSVersion = $computer.operatingSystem.version
                OSBuild = $computer.operatingSystem.build
                Username = $computer.userAndLocation.username
                RealName = $computer.userAndLocation.realName
                Email = $computer.userAndLocation.email
                Department = $computer.userAndLocation.department
                Building = $computer.userAndLocation.building
                Room = $computer.userAndLocation.room
                LastInventoryUpdate = $computer.general.lastInventoryUpdate
                LastContactTime = $computer.general.lastContactTime
                ManagementStatus = $computer.general.mdmCapable
            }
        }
        
        $fileName = "jamf_computers_inventory$timestamp.csv"
        $filePath = Join-Path $dataDirectory $fileName
        
        $flattenedData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
        Write-Log "CSV data exported to: $filePath" -Level "Info"
        return $filePath
    }
    catch {
        Write-Log "Failed to export CSV data: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}
#endregion

#region Main Execution
function Main {
    try {
        # Initialize output directory
        if (!(Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
        }
        
        # Load configuration first to get paths
        if (!(Test-Path $ConfigPath)) {
            Write-Host "Configuration file not found. Creating default configuration..." -ForegroundColor Yellow
            $Global:Config = New-DefaultConfiguration -ConfigFilePath $ConfigPath
            if (!$Global:Config) {
                throw "Failed to create configuration file"
            }
            Write-Host "Please update the configuration file with your JAMF Pro credentials and run the script again." -ForegroundColor Yellow
            return
        } else {
            $Global:Config = Load-Configuration -ConfigFilePath $ConfigPath
            if (!$Global:Config) {
                throw "Failed to load configuration file"
            }
        }

        # Initialize logging
        Initialize-Logging -OutputDirectory $OutputPath
        
        Write-Log "JAMF Pro Data Extraction Script Started" -Level "Info"
        Write-Log "Output Format: $OutputFormat" -Level "Info"
        Write-Log "Output Path: $OutputPath" -Level "Info"
        
        # Initialize proxy settings
        Initialize-ProxySettings -Config $Global:Config
        
        # Validate configuration
        if ($Global:Config.jamf.clientId -eq "YOUR_CLIENT_ID" -or $Global:Config.jamf.clientSecret -eq "YOUR_CLIENT_SECRET") {
            Write-Log "Please update the clientId and clientSecret in the configuration file." -Level "Error"
            return
        }
        
        # Get access token
        $Global:AccessToken = Get-AccessToken -BaseUrl $Global:Config.jamf.baseUrl -ClientId $Global:Config.jamf.clientId -ClientSecret $Global:Config.jamf.clientSecret
        if (!$Global:AccessToken) {
            throw "Failed to obtain access token"
        }
        
        # Test access token
        if (!(Test-AccessToken -BaseUrl $Global:Config.jamf.baseUrl -AccessToken $Global:AccessToken)) {
            throw "Access token validation failed"
        }
        
        # Extract computer inventory data
        Write-Log "Starting computer inventory data extraction..." -Level "Info"
        $computerData = Get-ComputersInventory -BaseUrl $Global:Config.jamf.baseUrl -AccessToken $Global:AccessToken -Sections $Global:Config.extraction.sections -PageSize $Global:Config.extraction.pageSize -SortBy $Global:Config.extraction.sortBy -MaxRetries $Global:Config.extraction.maxRetries -RetryDelay $Global:Config.extraction.retryDelaySeconds
        
        if ($computerData.Count -eq 0) {
            Write-Log "No computer data retrieved" -Level "Warning"
            return
        }
        
        # Export data based on output format
        $exportedFiles = @()
        
        if ($OutputFormat -eq "JSON" -or $OutputFormat -eq "Both") {
            $jsonFile = Export-ToJson -Data $computerData -OutputDirectory $OutputPath -IncludeTimestamp $Global:Config.output.includeTimestampInFilename
            if ($jsonFile) { $exportedFiles += $jsonFile }
        }
        
        if ($OutputFormat -eq "CSV" -or $OutputFormat -eq "Both") {
            $csvFile = Export-ToCsv -Data $computerData -OutputDirectory $OutputPath -IncludeTimestamp $Global:Config.output.includeTimestampInFilename
            if ($csvFile) { $exportedFiles += $csvFile }
        }
        
        # Summary
        Write-Log "Data extraction completed successfully!" -Level "Info"
        Write-Log "Total computers processed: $($computerData.Count)" -Level "Info"
        Write-Log "Files exported: $($exportedFiles.Count)" -Level "Info"
        foreach ($file in $exportedFiles) {
            Write-Log "  - $file" -Level "Info"
        }
        
        Write-Log "JAMF Pro Data Extraction Script Completed" -Level "Info"
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level "Error"
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level "Debug"
        exit 1
    }
}

# Execute main function
Main
#endregion