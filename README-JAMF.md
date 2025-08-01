# JAMF Pro API Data Extraction PowerShell Scripts

This repository contains PowerShell scripts to extract computer inventory data from JAMF Pro API on a regular basis using OAuth authentication.

## 📋 Overview

The solution includes:
- **`Get-JamfData.ps1`** - Main data extraction script
- **`Schedule-JamfDataExtraction.ps1`** - Windows Task Scheduler setup script
- **`config.json`** - Configuration file for API credentials and settings

## 🚀 Features

- **OAuth Authentication** - Secure API access using client credentials
- **Paginated Data Retrieval** - Handles large datasets efficiently
- **Multiple Output Formats** - JSON, CSV, or both
- **Comprehensive Logging** - Detailed logs with timestamps and levels
- **Error Handling & Retry Logic** - Robust error handling with configurable retries
- **Scheduled Execution** - Windows Task Scheduler integration
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
- **Windows OS** - For Task Scheduler functionality
- **Network Access** - To your JAMF Pro instance

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

### Manual Execution

```powershell
# Basic usage with default settings
.\Get-JamfData.ps1

# Specify custom parameters
.\Get-JamfData.ps1 -ConfigPath ".\config.json" -OutputFormat "Both" -OutputPath ".\data" -LogLevel "Info"

# JSON output only
.\Get-JamfData.ps1 -OutputFormat "JSON"

# CSV output only
.\Get-JamfData.ps1 -OutputFormat "CSV"

# Debug logging
.\Get-JamfData.ps1 -LogLevel "Debug"
```

### Schedule Regular Execution

```powershell
# Set up daily execution at 8:00 AM
.\Schedule-JamfDataExtraction.ps1 -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Daily" -StartTime "08:00"

# Set up hourly execution
.\Schedule-JamfDataExtraction.ps1 -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Hourly" -StartTime "09:00"

# Custom task name and weekly schedule
.\Schedule-JamfDataExtraction.ps1 -TaskName "Weekly JAMF Extract" -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Weekly" -StartTime "06:00"
```

## 📁 Output Structure

```
data/
├── logs/
│   └── jamf_extraction_20241215_143022.log
├── jamf_computers_inventory_20241215_143022.json
└── jamf_computers_inventory_20241215_143022.csv
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

## 🔧 Task Scheduler Management

After setting up the scheduled task, you can manage it using these PowerShell commands:

```powershell
# Start task manually
Start-ScheduledTask -TaskName "JAMF Pro Data Extraction"

# Stop running task
Stop-ScheduledTask -TaskName "JAMF Pro Data Extraction"

# Disable task
Disable-ScheduledTask -TaskName "JAMF Pro Data Extraction"

# Enable task
Enable-ScheduledTask -TaskName "JAMF Pro Data Extraction"

# Remove task
Unregister-ScheduledTask -TaskName "JAMF Pro Data Extraction" -Confirm:$false

# Get task information
Get-ScheduledTask -TaskName "JAMF Pro Data Extraction"
Get-ScheduledTaskInfo -TaskName "JAMF Pro Data Extraction"
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

#### Task Scheduler Permissions
```
Access is denied
```
**Solution**: Run the scheduling script as Administrator

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

### Schedule-JamfDataExtraction.ps1 Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| TaskName | String | "JAMF Pro Data Extraction" | Scheduled task name |
| ScriptPath | String | Required | Path to Get-JamfData.ps1 |
| Schedule | String | "Daily" | Schedule: Daily, Weekly, Monthly, Hourly |
| StartTime | String | "08:00" | Start time (HH:mm format) |
| RunAsUser | String | Current user | User account for task execution |

## 🔄 Automation Examples

### Daily Reports at 6 AM
```powershell
.\Schedule-JamfDataExtraction.ps1 -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Daily" -StartTime "06:00"
```

### Hourly Monitoring
```powershell
.\Schedule-JamfDataExtraction.ps1 -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Hourly" -StartTime "09:00"
```

### Weekly Summary
```powershell
.\Schedule-JamfDataExtraction.ps1 -TaskName "Weekly JAMF Summary" -ScriptPath "C:\Scripts\Get-JamfData.ps1" -Schedule "Weekly" -StartTime "07:00"
```

## 📞 Support

For issues and questions:
1. Check the log files for detailed error information
2. Review the troubleshooting section
3. Verify JAMF Pro API permissions
4. Test manual execution before scheduling

---

**Version**: 1.0  
**Author**: System Administrator  
**Last Updated**: December 2024