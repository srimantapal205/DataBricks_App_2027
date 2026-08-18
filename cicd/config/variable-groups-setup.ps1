# ============================================================================
# Azure DevOps Variable Groups Setup Script
# ============================================================================
# This script creates and configures all required variable groups for the
# CI/CD pipeline. Run this once to set up your Azure DevOps project.
#
# Prerequisites:
# - Azure DevOps CLI (az devops)
# - Authenticated to Azure DevOps
# - Proper permissions to create variable groups
#
# Usage:
#   .\variable-groups-setup.ps1 -OrganizationUrl "https://dev.azure.com/yourorg" -ProjectName "YourProject"
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateExisting
)

# Set Azure DevOps defaults
az devops configure --defaults organization=$OrganizationUrl project=$ProjectName

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Azure DevOps Variable Groups Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Organization: $OrganizationUrl" -ForegroundColor Yellow
Write-Host "Project: $ProjectName" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Function: Create or Update Variable Group
# ============================================================================
function Set-VariableGroup {
    param(
        [string]$GroupName,
        [hashtable]$Variables,
        [string]$Description
    )
    
    Write-Host "Processing variable group: $GroupName" -ForegroundColor Green
    
    # Check if group exists
    $existingGroup = az pipelines variable-group list --group-name $GroupName --query "[0].id" -o tsv 2>$null
    
    if ($existingGroup -and $UpdateExisting) {
        Write-Host "  Updating existing group (ID: $existingGroup)" -ForegroundColor Yellow
        
        # Update each variable
        foreach ($key in $Variables.Keys) {
            $value = $Variables[$key]
            az pipelines variable-group variable update `
                --group-id $existingGroup `
                --name $key `
                --value $value `
                --output none 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                # Variable doesn't exist, create it
                az pipelines variable-group variable create `
                    --group-id $existingGroup `
                    --name $key `
                    --value $value `
                    --output none
            }
            Write-Host "    ✓ $key" -ForegroundColor Gray
        }
    }
    elseif (-not $existingGroup) {
        Write-Host "  Creating new variable group" -ForegroundColor Yellow
        
        # Build variables parameter
        $varsArray = @()
        foreach ($key in $Variables.Keys) {
            $varsArray += "$key=$($Variables[$key])"
        }
        
        $varsString = $varsArray -join " "
        
        az pipelines variable-group create `
            --name $GroupName `
            --description $Description `
            --variables $varsString `
            --output none
        
        Write-Host "    ✓ Created with $($Variables.Count) variables" -ForegroundColor Gray
    }
    else {
        Write-Host "  Group exists. Use -UpdateExisting to update" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================================
# SHARED CONFIGURATION (Common across all environments)
# ============================================================================
Write-Host "Creating SHARED variable group..." -ForegroundColor Cyan
$sharedVars = @{
    # Azure Subscription
    "AZURE_SUBSCRIPTION_ID" = "YOUR_SUBSCRIPTION_ID"
    "AZURE_LOCATION" = "eastus"
    "AZURE_TENANT_ID" = "YOUR_TENANT_ID"
    
    # Terraform Backend
    "TF_STATE_STORAGE_ACCOUNT" = "tfstatestorage"
    "TF_STATE_CONTAINER" = "tfstate"
    
    # Databricks Common
    "DATABRICKS_WORKSPACE_PATH" = "/Shared/DataEngineering"
    "DATABRICKS_RESOURCE_ID" = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
    
    # Naming Convention
    "PROJECT_NAME" = "dataeng"
    "COMPANY_PREFIX" = "contoso"
    
    # Tags
    "TAG_COST_CENTER" = "Engineering"
    "TAG_MANAGED_BY" = "Terraform"
    "TAG_PROJECT" = "DataEngineering"
}

Set-VariableGroup `
    -GroupName "vg-shared-config" `
    -Variables $sharedVars `
    -Description "Shared configuration across all environments"

# ============================================================================
# DEV ENVIRONMENT CONFIGURATION
# ============================================================================
Write-Host "Creating DEV variable group..." -ForegroundColor Cyan
$devVars = @{
    # Environment
    "ENVIRONMENT" = "dev"
    "ENV_SHORT" = "dev"
    
    # Azure Service Connection
    "devServiceConnection" = "azure-dev-service-connection"
    "devResourceGroup" = "rg-dataeng-dev"
    
    # Azure Data Factory
    "DEV_ADF_NAME" = "adf-dataeng-dev"
    "DEV_ADF_RESOURCE_GROUP" = "rg-dataeng-dev"
    
    # Databricks
    "DEV_DATABRICKS_HOST" = "https://adb-xxxxx.azuredatabricks.net"
    "DEV_DATABRICKS_WORKSPACE_NAME" = "dbw-dataeng-dev"
    "DEV_DATABRICKS_WORKSPACE_ID" = "/subscriptions/xxx/resourceGroups/rg-dataeng-dev/providers/Microsoft.Databricks/workspaces/dbw-dataeng-dev"
    
    # SQL Database
    "DEV_SQL_SERVER" = "sql-dataeng-dev.database.windows.net"
    "DEV_SQL_DATABASE" = "sqldb-dataeng-dev"
    
    # Storage Account
    "DEV_STORAGE_ACCOUNT" = "stdataengdev"
    "DEV_DATA_LAKE_NAME" = "datalake-dev"
    
    # Key Vault
    "DEV_KEY_VAULT_NAME" = "kv-dataeng-dev"
    
    # Tags
    "TAG_ENVIRONMENT" = "Development"
}

Set-VariableGroup `
    -GroupName "vg-dev-config" `
    -Variables $devVars `
    -Description "DEV environment configuration"

# ============================================================================
# INT ENVIRONMENT CONFIGURATION
# ============================================================================
Write-Host "Creating INT variable group..." -ForegroundColor Cyan
$intVars = @{
    # Environment
    "ENVIRONMENT" = "int"
    "ENV_SHORT" = "int"
    
    # Azure Service Connection
    "intServiceConnection" = "azure-int-service-connection"
    "intResourceGroup" = "rg-dataeng-int"
    
    # Azure Data Factory
    "INT_ADF_NAME" = "adf-dataeng-int"
    "INT_ADF_RESOURCE_GROUP" = "rg-dataeng-int"
    
    # Databricks
    "INT_DATABRICKS_HOST" = "https://adb-xxxxx.azuredatabricks.net"
    "INT_DATABRICKS_WORKSPACE_NAME" = "dbw-dataeng-int"
    "INT_DATABRICKS_WORKSPACE_ID" = "/subscriptions/xxx/resourceGroups/rg-dataeng-int/providers/Microsoft.Databricks/workspaces/dbw-dataeng-int"
    
    # SQL Database
    "INT_SQL_SERVER" = "sql-dataeng-int.database.windows.net"
    "INT_SQL_DATABASE" = "sqldb-dataeng-int"
    
    # Storage Account
    "INT_STORAGE_ACCOUNT" = "stdataengint"
    "INT_DATA_LAKE_NAME" = "datalake-int"
    
    # Key Vault
    "INT_KEY_VAULT_NAME" = "kv-dataeng-int"
    
    # Tags
    "TAG_ENVIRONMENT" = "Integration"
}

Set-VariableGroup `
    -GroupName "vg-int-config" `
    -Variables $intVars `
    -Description "INT environment configuration"

# ============================================================================
# PRD ENVIRONMENT CONFIGURATION
# ============================================================================
Write-Host "Creating PRD variable group..." -ForegroundColor Cyan
$prdVars = @{
    # Environment
    "ENVIRONMENT" = "prd"
    "ENV_SHORT" = "prd"
    
    # Azure Service Connection
    "prdServiceConnection" = "azure-prd-service-connection"
    "prdResourceGroup" = "rg-dataeng-prd"
    
    # Azure Data Factory
    "PRD_ADF_NAME" = "adf-dataeng-prd"
    "PRD_ADF_RESOURCE_GROUP" = "rg-dataeng-prd"
    
    # Databricks
    "PRD_DATABRICKS_HOST" = "https://adb-xxxxx.azuredatabricks.net"
    "PRD_DATABRICKS_WORKSPACE_NAME" = "dbw-dataeng-prd"
    "PRD_DATABRICKS_WORKSPACE_ID" = "/subscriptions/xxx/resourceGroups/rg-dataeng-prd/providers/Microsoft.Databricks/workspaces/dbw-dataeng-prd"
    
    # SQL Database
    "PRD_SQL_SERVER" = "sql-dataeng-prd.database.windows.net"
    "PRD_SQL_DATABASE" = "sqldb-dataeng-prd"
    
    # Storage Account
    "PRD_STORAGE_ACCOUNT" = "stdataengprd"
    "PRD_DATA_LAKE_NAME" = "datalake-prd"
    
    # Key Vault
    "PRD_KEY_VAULT_NAME" = "kv-dataeng-prd"
    
    # Tags
    "TAG_ENVIRONMENT" = "Production"
}

Set-VariableGroup `
    -GroupName "vg-prd-config" `
    -Variables $prdVars `
    -Description "PRD environment configuration"

# ============================================================================
# Summary
# ============================================================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Variable Groups Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created/Updated variable groups:" -ForegroundColor Yellow
Write-Host "  ✓ vg-shared-config (Shared configuration)" -ForegroundColor Green
Write-Host "  ✓ vg-dev-config (DEV environment)" -ForegroundColor Green
Write-Host "  ✓ vg-int-config (INT environment)" -ForegroundColor Green
Write-Host "  ✓ vg-prd-config (PRD environment)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update the variable values in Azure DevOps Library" -ForegroundColor White
Write-Host "2. Set up Service Connections in Azure DevOps" -ForegroundColor White
Write-Host "3. Configure approval gates for PRD environment" -ForegroundColor White
Write-Host "4. Test the pipeline with a sample deployment" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan