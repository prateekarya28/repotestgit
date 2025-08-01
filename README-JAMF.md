# JAMF Pro API Data Extraction PowerShell Scripts

This repository contains PowerShell scripts to extract computer inventory data from JAMF Pro API on a regular basis using OAuth authentication.

## 📋 Overview

The solution includes:
- **`Get-JamfData.ps1`** - Main data extraction script
- **`Test-JamfConnection.ps1`** - Connection and credential validation script
- **`config.json`** - Configuration file for API credentials and settings

## 🚀 Features

- **OAuth Authentication** - Secure API access using client credentials
- **Paginated Data Retrieval** - Handles large datasets efficiently
- **Multiple Output Formats** - JSON, CSV, or both
- **Comprehensive Logging** - Detailed logs with timestamps and levels
- **Error Handling & Retry Logic** - Robust error handling with configurable retries
- **Enterprise Integration Ready** - Designed for integration with enterprise scheduling systems (e.g., Hitachi PDI)
- **Configurable Sections** - Extract specific data sections from JAMF Pro
- **Timestamp Support** - Optional timestamped filenames

## 📊 Data Sections Extracted

The script extracts the following sections from JAMF Pro:
- **GENERAL** - Basic computer information
- **USER_AND_LOCATION** - User and location details
- **HARDWARE** - Hardware specifications
- **OPERATING_SYSTEM** - OS information
- **SOFTWARE_UPDATES** - Software update status

## 🛠️ Prerequisites

- **PowerShell 5.1** or later
- **JAMF Pro API Access** - Client ID and Client Secret
- **CredentialManager Module** - For proxy authentication
- **Network Access** - To your JAMF Pro instance (via proxy if configured)

## ⚙️ Configuration

### 1. Update Configuration File

Edit `config.json` with your JAMF Pro details:

```json
{
  "jamf": {
    "baseUrl": "https://stmicroelectronics.jamfcloud.com",
    "clientId": "YOUR_ACTUAL_CLIENT_ID",
    "clientSecret": "YOUR_ACTUAL_CLIENT_SECRET",
    "apiVersion": "v1"
  },
  "extraction": {
    "sections": [
      "GENERAL",
      "USER_AND_LOCATION", 
      "HARDWARE",
      "OPERATING_SYSTEM",
      "SOFTWARE_UPDATES"
    ],
    "pageSize": 100,
    "sortBy": "general.name:asc",
    "maxRetries": 3,
    "retryDelaySeconds": 5
  },
  "output": {
    "timestampFormat": "yyyyMMdd_HHmmss",
    "includeTimestampInFilename": true,
    "compressOutput": false
  }
}
```

### 2. JAMF Pro API Setup

1. **Login to JAMF Pro** as an administrator
2. **Navigate to** Settings > System > API Roles and Clients
3. **Create API Client** with the following permissions:
   - Read Computers
   - Read Computer Inventory Collection
4. **Note the Client ID and Client Secret** for configuration

## 🎯 Usage

### Test Connection First

```powershell
# Test your configuration and connectivity
.\Test-JamfConnection.ps1 -ConfigPath ".\config.json"
```

### Manual Execution

```powershell
# Basic usage with default settings
.\Get-JamfData.ps1

# Specify custom parameters
.\Get-JamfData.ps1 -ConfigPath ".\config.json" -OutputFormat "Both" -OutputPath "C:\backend\data-integration4\scripts\jamf\data" -LogLevel "Info"

# JSON output only
.\Get-JamfData.ps1 -OutputFormat "JSON"

# CSV output only
.\Get-JamfData.ps1 -OutputFormat "CSV"

# Debug logging
.\Get-JamfData.ps1 -LogLevel "Debug"
```

### Enterprise Scheduling Integration

For production environments, this script is designed to be integrated with enterprise scheduling systems such as:

- **Hitachi PDI (Pentaho Data Integration)** - Call the PowerShell script as part of your data pipeline
- **Apache Airflow** - Use PowerShell operator to execute the script
- **Control-M** - Schedule as a PowerShell job
- **Other ETL/Orchestration tools** - Execute via command line interface

Example for PDI/Kettle integration:
```bash
# Command line execution for PDI
powershell.exe -ExecutionPolicy Bypass -File "C:\backend\data-integration4\scripts\jamf\Get-JamfData.ps1"
```

## 📁 Output Structure

```
C:\backend\data-integration4\scripts\jamf\
├── data/
│   ├── jamf_computers_inventory_20241215_143022.json
│   └── jamf_computers_inventory_20241215_143022.csv
├── logs/
│   └── jamf_extraction_20241215_143022.log
├── Get-JamfData.ps1
├── Test-JamfConnection.ps1
└── config.json
```

### JSON Output Structure

```json
[
  {
    "general": {
      "id": "123",
      "name": "COMPUTER-001",
      "serialNumber": "ABC123DEF456",
      "assetTag": "TAG001",
      "lastInventoryUpdate": "2024-12-15T14:30:22Z"
    },
    "hardware": {
      "model": "MacBook Pro",
      "modelFamily": "MacBook Pro",
      "processorType": "Apple M1",
      "totalRamMegabytes": 16384
    },
    "operatingSystem": {
      "name": "macOS",
      "version": "14.2.1",
      "build": "23C71"
    },
    "userAndLocation": {
      "username": "john.doe",
      "realName": "John Doe",
      "email": "john.doe@company.com",
      "department": "IT"
    }
  }
]
```

### CSV Output Fields

| Field | Description |
|-------|-------------|
| ComputerId | Unique computer identifier |
| ComputerName | Computer name |
| SerialNumber | Hardware serial number |
| AssetTag | Asset tag |
| Model | Hardware model |
| ModelFamily | Hardware model family |
| Processor | Processor type |
| ProcessorSpeed | Processor speed in MHz |
| TotalRAM | Total RAM in MB |
| OSName | Operating system name |
| OSVersion | OS version |
| OSBuild | OS build number |
| Username | Associated username |
| RealName | User's real name |
| Email | User's email |
| Department | User's department |
| Building | Location building |
| Room | Location room |
| LastInventoryUpdate | Last inventory update timestamp |
| LastContactTime | Last contact timestamp |
| ManagementStatus | MDM management status |

## 🔧 Enterprise Integration Considerations

### Hitachi PDI Integration Tips:
- Use **Execute a shell script** step to call the PowerShell script
- Set proper **working directory** to the script location
- Configure **error handling** in your PDI transformation
- Use PDI **logging** to capture script output
- Consider **parallel execution** for multiple data sources

### Return Codes:
- **0** - Success
- **1** - Configuration or authentication error
- **2** - Network connectivity error
- **3** - Data extraction error

### Environment Variables:
You can override config settings using environment variables in your pipeline:
```powershell
$env:JAMF_CLIENT_ID = "your_client_id"
$env:JAMF_CLIENT_SECRET = "your_client_secret"
$env:JAMF_OUTPUT_PATH = "custom_path"
```

## 📝 Logging

The script provides comprehensive logging with different levels:

- **Info** - General information and progress
- **Warning** - Non-critical issues
- **Error** - Critical errors
- **Debug** - Detailed debugging information

Log files are automatically created with timestamps in the `logs/` directory.

## 🔒 Security Considerations

1. **Secure Credentials** - Store API credentials securely
2. **File Permissions** - Restrict access to configuration files
3. **Network Security** - Ensure secure connection to JAMF Pro
4. **Log Security** - Protect log files containing sensitive information
5. **Scheduled Task Security** - Run with appropriate user permissions

## 🐛 Troubleshooting

### Common Issues

#### Authentication Errors
```
Failed to obtain access token: The remote server returned an error: (401) Unauthorized
```
**Solution**: Verify Client ID and Client Secret in `config.json`

#### Network Connectivity
```
Failed to obtain access token: Unable to connect to the remote server
```
**Solution**: Check network connectivity and JAMF Pro URL

#### PowerShell Execution Policy
```
Execution of scripts is disabled on this system
```
**Solution**: Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### PDI Integration Issues
```
PowerShell execution policy error
```
**Solution**: Set execution policy in PDI step:
```bash
powershell.exe -ExecutionPolicy Bypass -File "script.ps1"
```

### Debug Mode

Enable debug logging for detailed troubleshooting:
```powershell
.\Get-JamfData.ps1 -LogLevel "Debug"
```

## 📋 Parameters Reference

### Get-JamfData.ps1 Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| ConfigPath | String | ".\config.json" | Path to configuration file |
| OutputFormat | String | "Both" | Output format: JSON, CSV, or Both |
| OutputPath | String | ".\data" | Output directory path |
| LogLevel | String | "Info" | Logging level: Info, Warning, Error, Debug |

### Test-JamfConnection.ps1 Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| ConfigPath | String | ".\config.json" | Path to configuration file |

## 🔄 PDI Integration Examples

### Basic PDI Transformation Step
```xml
<step>
  <name>JAMF Data Extract</name>
  <type>ShellScript</type>
  <script>powershell.exe -ExecutionPolicy Bypass -File "C:\backend\data-integration4\scripts\jamf\Get-JamfData.ps1"</script>
  <working_directory>C:\backend\data-integration4\scripts\jamf</working_directory>
</step>
```

### PDI with Error Handling
```xml
<step>
  <name>JAMF Data Extract with Retry</name>
  <type>ShellScript</type>
  <script>
    for i in {1..3}; do
      powershell.exe -ExecutionPolicy Bypass -File "Get-JamfData.ps1" && break
      sleep 60
    done
  </script>
</step>
```

### PDI with Custom Output Path
```xml
<step>
  <name>JAMF Data Extract Custom</name>
  <type>ShellScript</type>
  <script>powershell.exe -ExecutionPolicy Bypass -File "Get-JamfData.ps1" -OutputPath "${PDI_OUTPUT_DIR}"</script>
</step>
```

## 📞 Support

For issues and questions:
1. Run `Test-JamfConnection.ps1` first to validate configuration
2. Check the log files for detailed error information  
3. Review the troubleshooting section
4. Verify JAMF Pro API permissions
5. Test manual execution before PDI integration
6. Contact for PDI integration assistance if needed

---

**Version**: 1.0  
**Author**: System Administrator  
**Last Updated**: December 2024