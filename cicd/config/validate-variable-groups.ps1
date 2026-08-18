# ============================================================================
# Validate Azure DevOps Variable Groups
# ============================================================================
# This script validates that all required variable groups and variables exist
# and have non-placeholder values. Use this to verify configuration completeness.
#
# Usage:
#   .\validate-variable-groups.ps1 -OrganizationUrl "https://dev.azure.com/yourorg" -ProjectName "YourProject"
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "./variable-groups-validation-report.txt"
)

# Set Azure DevOps defaults
az devops configure --defaults organization=$OrganizationUrl project=$ProjectName

Write-Host "" 
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Variable Groups Validation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Organization: $OrganizationUrl" -ForegroundColor Yellow
Write-Host "Project: $ProjectName" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$warnings = @()
$validationReport = @()

# ============================================================================
# Define Required Variables
# ============================================================================

$requiredVariableGroups = @{
    "vg-shared-config" = @(
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_LOCATION",
        "AZURE_TENANT_ID",
        "TF_STATE_STORAGE_ACCOUNT",
        "TF_STATE_CONTAINER",
        "DATABRICKS_WORKSPACE_PATH",
        "DATABRICKS_RESOURCE_ID",
        "PROJECT_NAME",
        "COMPANY_PREFIX"
    )
    "vg-dev-config" = @(
        "ENVIRONMENT",
        "devServiceConnection",
        "devResourceGroup",
        "DEV_ADF_NAME",
        "DEV_DATABRICKS_HOST",
        "DEV_SQL_SERVER",
        "DEV_STORAGE_ACCOUNT",
        "DEV_KEY_VAULT_NAME"
    )
    "vg-int-config" = @(
        "ENVIRONMENT",
        "intServiceConnection",
        "intResourceGroup",
        "INT_ADF_NAME",
        "INT_DATABRICKS_HOST",
        "INT_SQL_SERVER",
        "INT_STORAGE_ACCOUNT",
        "INT_KEY_VAULT_NAME"
    )
    "vg-prd-config" = @(
        "ENVIRONMENT",
        "prdServiceConnection",
        "prdResourceGroup",
        "PRD_ADF_NAME",
        "PRD_DATABRICKS_HOST",
        "PRD_SQL_SERVER",
        "PRD_STORAGE_ACCOUNT",
        "PRD_KEY_VAULT_NAME"
    )
}

$placeholderPatterns = @(
    "YOUR_",
    "xxx",
    "REPLACE",
    "CHANGE_ME",
    "TODO"
)

# ============================================================================
# Validation Function
# ============================================================================

function Test-VariableGroup {
    param(
        [string]$GroupName,
        [array]$RequiredVariables
    )
    
    Write-Host "Validating: $GroupName" -ForegroundColor Green
    $validationReport += "`nValidating: $GroupName"
    
    # Check if group exists
    $group = az pipelines variable-group list --group-name $GroupName --query "[0]" 2>$null | ConvertFrom-Json
    
    if (-not $group) {
        $issue = "✗ CRITICAL: Variable group '$GroupName' does not exist"
        Write-Host "  $issue" -ForegroundColor Red
        $script:issues += $issue
        $script:validationReport += "  $issue"
        return $false
    }
    
    Write-Host "  ✓ Group exists (ID: $($group.id))" -ForegroundColor Gray
    $script:validationReport += "  ✓ Group exists (ID: $($group.id))"
    
    # Get all variables in the group
    $existingVariables = $group.variables.PSObject.Properties.Name
    
    $groupValid = $true
    
    # Check each required variable
    foreach ($varName in $RequiredVariables) {
        if ($varName -notin $existingVariables) {
            $issue = "✗ MISSING: Variable '$varName' not found in $GroupName"
            Write-Host "  $issue" -ForegroundColor Red
            $script:issues += $issue
            $script:validationReport += "  $issue"
            $groupValid = $false
        }
        else {
            # Variable exists, check if it's a placeholder
            $varValue = $group.variables.$varName.value
            $isSecret = $group.variables.$varName.isSecret
            
            if ($isSecret) {
                Write-Host "  ✓ $varName (secret)" -ForegroundColor Gray
                $script:validationReport += "  ✓ $varName (secret)"
            }
            else {
                # Check for placeholder values
                $isPlaceholder = $false
                foreach ($pattern in $placeholderPatterns) {
                    if ($varValue -like "*$pattern*") {
                        $isPlaceholder = $true
                        break
                    }
                }
                
                if ($isPlaceholder) {
                    $warning = "⚠️ WARNING: Variable '$varName' appears to be a placeholder: $varValue"
                    Write-Host "  $warning" -ForegroundColor Yellow
                    $script:warnings += $warning
                    $script:validationReport += "  $warning"
                }
                else {
                    Write-Host "  ✓ $varName" -ForegroundColor Gray
                    $script:validationReport += "  ✓ $varName"
                }
            }
        }
    }
    
    Write-Host ""
    return $groupValid
}

# ============================================================================
# Run Validation
# ============================================================================

$allValid = $true

foreach ($groupName in $requiredVariableGroups.Keys) {
    $result = Test-VariableGroup -GroupName $groupName -RequiredVariables $requiredVariableGroups[$groupName]
    if (-not $result) {
        $allValid = $false
    }
}

# ============================================================================
# Validation Summary
# ============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$validationReport += "`n============================================"
$validationReport += "Validation Summary"
$validationReport += "============================================"
$validationReport += ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ All variable groups are configured correctly!" -ForegroundColor Green
    $validationReport += "✓ All variable groups are configured correctly!"
}
else {
    if ($issues.Count -gt 0) {
        Write-Host "✗ CRITICAL ISSUES FOUND: $($issues.Count)" -ForegroundColor Red
        $validationReport += "✗ CRITICAL ISSUES FOUND: $($issues.Count)"
        Write-Host ""
        foreach ($issue in $issues) {
            Write-Host "  $issue" -ForegroundColor Red
            $validationReport += "  $issue"
        }
        Write-Host ""
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "⚠️ WARNINGS: $($warnings.Count)" -ForegroundColor Yellow
        $validationReport += "⚠️ WARNINGS: $($warnings.Count)"
        Write-Host ""
        foreach ($warning in $warnings) {
            Write-Host "  $warning" -ForegroundColor Yellow
            $validationReport += "  $warning"
        }
        Write-Host ""
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Additional Checks
# ============================================================================

Write-Host "Additional Checks:" -ForegroundColor Cyan
$validationReport += "Additional Checks:"
Write-Host ""

# Check service connections
Write-Host "Checking Service Connections..." -ForegroundColor Green
$validationReport += "Checking Service Connections..."

$serviceConnections = @(
    "azure-dev-service-connection",
    "azure-int-service-connection",
    "azure-prd-service-connection"
)

foreach ($conn in $serviceConnections) {
    $exists = az devops service-endpoint list --query "[?name=='$conn'].id" -o tsv 2>$null
    if ($exists) {
        Write-Host "  ✓ Service connection '$conn' exists" -ForegroundColor Gray
        $validationReport += "  ✓ Service connection '$conn' exists"
    }
    else {
        Write-Host "  ✗ Service connection '$conn' NOT FOUND" -ForegroundColor Red
        $validationReport += "  ✗ Service connection '$conn' NOT FOUND"
        $allValid = $false
    }
}

Write-Host ""

# Check environments
Write-Host "Checking Environments..." -ForegroundColor Green
$validationReport += "Checking Environments..."

$environments = @("DEV", "INT", "PRD")

foreach ($env in $environments) {
    $exists = az pipelines environment list --query "[?name=='$env'].id" -o tsv 2>$null
    if ($exists) {
        Write-Host "  ✓ Environment '$env' exists" -ForegroundColor Gray
        $validationReport += "  ✓ Environment '$env' exists"
    }
    else {
        Write-Host "  ⚠️ Environment '$env' not found (will be created on first run)" -ForegroundColor Yellow
        $validationReport += "  ⚠️ Environment '$env' not found (will be created on first run)"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

# ============================================================================
# Recommendations
# ============================================================================

if ($warnings.Count -gt 0 -or $issues.Count -gt 0) {
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Cyan
    $validationReport += ""
    $validationReport += "Recommendations:"
    
    if ($issues.Count -gt 0) {
        Write-Host "1. Fix critical issues before running the pipeline" -ForegroundColor Yellow
        Write-Host "2. Use variable-groups-setup.ps1 to create missing variable groups" -ForegroundColor Yellow
        Write-Host "3. Create missing service connections in Azure DevOps" -ForegroundColor Yellow
        $validationReport += "1. Fix critical issues before running the pipeline"
        $validationReport += "2. Use variable-groups-setup.ps1 to create missing variable groups"
        $validationReport += "3. Create missing service connections in Azure DevOps"
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "4. Replace placeholder values in variable groups" -ForegroundColor Yellow
        Write-Host "5. Navigate to Azure DevOps -> Pipelines -> Library" -ForegroundColor Yellow
        Write-Host "6. Update each variable group with actual values" -ForegroundColor Yellow
        $validationReport += "4. Replace placeholder values in variable groups"
        $validationReport += "5. Navigate to Azure DevOps -> Pipelines -> Library"
        $validationReport += "6. Update each variable group with actual values"
    }
    
    Write-Host ""
}

# ============================================================================
# Export Report
# ============================================================================

if ($ExportReport) {
    $validationReport | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Validation report exported to: $ReportPath" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# Exit Code
# ============================================================================

if ($allValid -and $issues.Count -eq 0) {
    Write-Host "Validation completed successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Validation completed with issues. Please review and fix." -ForegroundColor Red
    exit 1
}