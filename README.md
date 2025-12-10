# Azure Tag Find

A PowerShell script to efficiently search Azure resources by tag name (key) or tag value using Azure Resource Graph KQL queries.

## Description

This script provides a fast and efficient way to find Azure resources based on their tags. It leverages Azure Resource Graph with optimized KQL queries to search across subscriptions or an entire tenant, making it ideal for large-scale Azure environments.

### Key Features

- **Search by Tag Name**: Find all resources that have a specific tag key
- **Search by Tag Value**: Find all resources where any tag has a specific value
- **Tenant-wide Search**: Query across all subscriptions in your tenant (subject to RBAC permissions)
- **Efficient Pagination**: Handles large result sets with automatic batching (1000 resources per batch)
- **Formatted Output**: Clean, readable table display of results

## Prerequisites

### Required PowerShell Modules

- `Az.Accounts` - For Azure authentication
- `Az.ResourceGraph` - For querying Azure Resource Graph

### Installation

Install the required Azure PowerShell modules if not already installed:

```powershell
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
Install-Module -Name Az.ResourceGraph -Scope CurrentUser -Force
```

### Azure Permissions

You need appropriate RBAC permissions to query Azure Resource Graph:
- **Reader** role or higher on the subscriptions/resources you want to query
- For tenant-wide searches, you need read access across multiple subscriptions

## Setup

1. **Clone the repository**:
   ```powershell
   git clone https://github.com/gplima89/AzureTagFind.git
   cd AzureTagFind
   ```

2. **Authenticate to Azure**:
   ```powershell
   Connect-AzAccount
   ```
   
   The script will automatically prompt for authentication if not already connected.

## Usage

### Basic Syntax

```powershell
.\tagvaluefind.ps1 [-TagValue <string>] [-TagName <string>] [-SearchByValue] [-SearchByName] [-UseTenantScope]
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-TagValue` | String | The tag value to search for (use with `-SearchByValue`) |
| `-TagName` | String | The tag name/key to search for (use with `-SearchByName`) |
| `-SearchByValue` | Switch | Search for resources that have the specified tag value |
| `-SearchByName` | Switch | Search for resources that have the specified tag name/key |
| `-UseTenantScope` | Switch | Search across entire tenant (all accessible subscriptions) |

### Examples

#### Example 1: Search by Tag Value
Find all resources where any tag has the value "Example":

```powershell
.\tagvaluefind.ps1 -TagValue "Example" -SearchByValue -UseTenantScope
```

#### Example 2: Search by Tag Name
Find all resources that have a tag named "Environment":

```powershell
.\tagvaluefind.ps1 -TagName "Environment" -SearchByName -UseTenantScope
```

#### Example 3: Search in Current Subscription Only
Find resources with tag name "CostCenter" in your current subscription context:

```powershell
.\tagvaluefind.ps1 -TagName "CostCenter" -SearchByName
```

#### Example 4: Find Resources by Specific ID Tag
Find all resources tagged with a specific ID value:

```powershell
.\tagvaluefind.ps1 -TagValue "ProjectX-2024" -SearchByValue -UseTenantScope
```

## Output

The script displays results in a formatted table with the following columns:
- **name**: Resource name
- **tagKey**: The tag key that matched
- **tagValue**: The value of the matching tag
- **type**: Azure resource type
- **resourceGroup**: Resource group name
- **location**: Azure region

Example output:
```
========================================
RESOURCES WITH TAG VALUE: Example
========================================
Found 3 resources with tag value 'Example'

name                  tagKey      tagValue type                          resourceGroup  location
----                  ------      -------- ----                          -------------  --------
webapp-prod-001       ProjectID   Example     Microsoft.Web/sites           rg-prod        eastus
sqldb-analytics       CostCode    Example     Microsoft.Sql/servers         rg-database    westus2
storage-logs-prod     Department  Example     Microsoft.Storage/storageAc.. rg-storage     centralus

========================================
Total: 3 resources
========================================
```

## How It Works

1. **Authentication**: Checks for existing Azure context or prompts for login
2. **Parameter Validation**: Ensures required parameters are provided
3. **KQL Query Generation**: Builds optimized query based on search type
4. **Pagination**: Retrieves results in batches of 1000 resources
5. **Display**: Formats and displays results in a readable table

### Performance Notes

- Uses Azure Resource Graph for fast queries across large environments
- Handles pagination automatically for large result sets
- More efficient than iterating through individual resources with `Get-AzResource`

## Troubleshooting

### Common Issues

**Error: "You must specify either -SearchByValue or -SearchByName"**
- Solution: Choose one search mode and provide the corresponding parameter

**Error: "TagValue parameter is required when using -SearchByValue"**
- Solution: Provide a value for the `-TagValue` parameter

**Warning: "No resources found..."**
- The tag name/value doesn't exist in your accessible resources
- Check spelling and case sensitivity
- Verify you have read permissions on the resources

**Module not found errors**
- Run the installation commands in the Prerequisites section

## Contributing

Feel free to submit issues or pull requests to improve this script.

## License

This project is open source and available under the MIT License.

## Author

Guil Lima
Microsoft - IaaS/IA CSA
guillima@microsoft.com