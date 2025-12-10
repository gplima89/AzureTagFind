<#
.SYNOPSIS
  Find Azure resources by tag name (key) or tag value using optimized Resource Graph KQL query.

.PARAMETER TagValue
  The tag value to search for. Use with -SearchByValue switch.

.PARAMETER TagName
  The tag name (key) to search for. Use with -SearchByName switch.

.PARAMETER SearchByValue
  Search for resources that have the specified tag value in any tag.

.PARAMETER SearchByName
  Search for resources that have the specified tag name (key).

.PARAMETER UseTenantScope
  Search across entire tenant (subject to RBAC permissions).

.EXAMPLE
  .\tagvaluefind.ps1 -TagValue "Example" -SearchByValue -UseTenantScope
  Finds all resources where any tag has the value "Example"

.EXAMPLE
  .\tagvaluefind.ps1 -TagName "Example" -SearchByName -UseTenantScope
  Finds all resources that have a tag named "Example"

.EXAMPLE
  .\tagvaluefind.ps1 -TagName "Environment" -SearchByName -UseTenantScope
  Finds all resources that have an "Environment" tag
#>

param(
    [string]$TagValue = "",
    [string]$TagName = "",
    [switch]$SearchByValue,
    [switch]$SearchByName,
    [switch]$UseTenantScope
)

# Ensure required modules are loaded
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.ResourceGraph -ErrorAction Stop

# Check Azure context
if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount | Out-Null
}

# Validate parameters
if (-not $SearchByValue -and -not $SearchByName) {
    Write-Error "You must specify either -SearchByValue or -SearchByName"
    Write-Host "`nExamples:" -ForegroundColor Cyan
    Write-Host "  Search by value: .\tagvaluefind.ps1 -TagValue 'Example' -SearchByValue -UseTenantScope" -ForegroundColor Gray
    Write-Host "  Search by name:  .\tagvaluefind.ps1 -TagName 'Example' -SearchByName -UseTenantScope" -ForegroundColor Gray
    exit 1
}

if ($SearchByValue -and $SearchByName) {
    Write-Error "Cannot use both -SearchByValue and -SearchByName at the same time"
    exit 1
}

if ($SearchByValue -and [string]::IsNullOrWhiteSpace($TagValue)) {
    Write-Error "TagValue parameter is required when using -SearchByValue"
    exit 1
}

if ($SearchByName -and [string]::IsNullOrWhiteSpace($TagName)) {
    Write-Error "TagName parameter is required when using -SearchByName"
    exit 1
}

# Build appropriate KQL query based on search mode
if ($SearchByName) {
    Write-Host " #-# Searching for tag name (key) '$TagName' using Resource Graph KQL #-# " -ForegroundColor Cyan
    
    # Search for resources that have a specific tag name/key
    $kql = @"
resources
| where isnotnull(tags['$TagName'])
| extend tagKey = '$TagName'
| extend tagValue = tostring(tags['$TagName'])
| project name, type, resourceGroup, location, subscriptionId, tagKey, tagValue, id
| order by name asc
"@
} else {
    Write-Host " #-# Searching for tag value '$TagValue' using Resource Graph KQL #-# " -ForegroundColor Cyan
    
    # Search for resources where any tag has the specified value
    $kql = @"
resources
| where notnull(tags)
| mvexpand tags
| extend tagKey = tostring(bag_keys(tags)[0])
| extend tagValue = tostring(tags[tagKey])
| where tagValue == '$TagValue'
| project name, type, resourceGroup, location, subscriptionId, tagKey, tagValue, id
| order by name asc
"@
}

try {
    # Execute query with pagination
    $results = @()
    $skip = 0
    $batchSize = 1000
    
    Write-Host "Querying Azure Resource Graph..." -ForegroundColor Cyan
    
    do {
        if ($skip -eq 0) {
            if ($UseTenantScope) {
                $batch = Search-AzGraph -Query $kql -First $batchSize -UseTenantScope
            } else {
                $batch = Search-AzGraph -Query $kql -First $batchSize
            }
        } else {
            if ($UseTenantScope) {
                $batch = Search-AzGraph -Query $kql -First $batchSize -Skip $skip -UseTenantScope
            } else {
                $batch = Search-AzGraph -Query $kql -First $batchSize -Skip $skip
            }
        }
        
        if ($batch) {
            # Convert PSResourceGraphResponse to array before adding
            $batchArray = @($batch)
            $results += $batchArray
            Write-Host "Retrieved $($batchArray.Count) resources (Total: $($results.Count))..." -ForegroundColor Gray
        }
        
        $skip += $batchSize
    } while ($batch -and @($batch).Count -eq $batchSize)
    
    # Display results
    Write-Host "`n========================================" -ForegroundColor Cyan
    if ($SearchByName) {
        Write-Host "RESOURCES WITH TAG NAME: $TagName" -ForegroundColor Cyan
    } else {
        Write-Host "RESOURCES WITH TAG VALUE: $TagValue" -ForegroundColor Cyan
    }
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($results.Count -gt 0) {
        if ($SearchByName) {
            Write-Host "Found $($results.Count) resources with tag name '$TagName'" -ForegroundColor Green
        } else {
            Write-Host "Found $($results.Count) resources with tag value '$TagValue'" -ForegroundColor Green
        }
        Write-Host ""
        
        # Display formatted table
        $results | Select-Object name, tagKey, tagValue, type, resourceGroup, location | Format-Table -AutoSize
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Total: $($results.Count) resources" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Cyan
    } else {
        if ($SearchByName) {
            Write-Warning "No resources found with tag name '$TagName'"
        } else {
            Write-Warning "No resources found with tag value '$TagValue'"
        }
    }
    
} catch {
    Write-Error "Failed to query Azure Resource Graph: $($_.Exception.Message)"
    throw
}