# ============================================================================
# Change Detection Script
# ============================================================================
# Detects which components have changed between source and target branches
# Sets Azure DevOps pipeline output variables for conditional deployment
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceBranch,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetBranch
)

# Initialize change flags
$adfChanged = $false
$databricksChanged = $false
$sqlChanged = $false
$terraformChanged = $false
$testsChanged = $false
$configChanged = $false
$scriptsChanged = $false

Write-Host "============================================"
Write-Host "Change Detection Analysis"
Write-Host "============================================"
Write-Host "Source Branch: $SourceBranch"
Write-Host "Target Branch: $TargetBranch"
Write-Host "============================================"

# Get the diff between branches
try {
    # Fetch both branches
    Write-Host "Fetching branches..."
    git fetch origin $SourceBranch
    git fetch origin $TargetBranch
    
    # Get list of changed files
    Write-Host "Analyzing changed files..."
    $changedFiles = git diff --name-only "origin/$TargetBranch"..."origin/$SourceBranch"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get git diff"
        exit 1
    }
    
    Write-Host ""
    Write-Host "Changed Files:"
    Write-Host "============================================"
    $changedFiles | ForEach-Object { Write-Host "  $_" }
    Write-Host "============================================"
    Write-Host ""
    
    # Analyze each changed file
    foreach ($file in $changedFiles) {
        
        # Check ADF changes
        if ($file -match '^adf/') {
            $adfChanged = $true
            Write-Host "[DETECTED] ADF change: $file"
        }
        
        # Check Databricks changes
        if ($file -match '^databricks/') {
            $databricksChanged = $true
            Write-Host "[DETECTED] Databricks change: $file"
        }
        
        # Check SQL changes
        if ($file -match '^sql/') {
            $sqlChanged = $true
            Write-Host "[DETECTED] SQL change: $file"
        }
        
        # Check Terraform/Infrastructure changes
        if ($file -match '^infrastructure/' -or $file -match '^terraform/') {
            $terraformChanged = $true
            Write-Host "[DETECTED] Infrastructure change: $file"
        }
        
        # Check Test changes
        if ($file -match '^tests/') {
            $testsChanged = $true
            Write-Host "[DETECTED] Test change: $file"
        }
        
        # Check Config changes
        if ($file -match '^config/') {
            $configChanged = $true
            Write-Host "[DETECTED] Config change: $file"
        }
        
        # Check Scripts changes
        if ($file -match '^scripts/') {
            $scriptsChanged = $true
            Write-Host "[DETECTED] Script change: $file"
        }
    }
    
} catch {
    Write-Error "Error during change detection: $_"
    exit 1
}

Write-Host ""
Write-Host "============================================"
Write-Host "Change Detection Summary"
Write-Host "============================================"
Write-Host "ADF Changed:        $adfChanged"
Write-Host "Databricks Changed: $databricksChanged"
Write-Host "SQL Changed:        $sqlChanged"
Write-Host "Terraform Changed:  $terraformChanged"
Write-Host "Tests Changed:      $testsChanged"
Write-Host "Config Changed:     $configChanged"
Write-Host "Scripts Changed:    $scriptsChanged"
Write-Host "============================================"

# Set Azure DevOps output variables
Write-Host "##vso[task.setvariable variable=ADF_CHANGED;isOutput=true]$adfChanged"
Write-Host "##vso[task.setvariable variable=DATABRICKS_CHANGED;isOutput=true]$databricksChanged"
Write-Host "##vso[task.setvariable variable=SQL_CHANGED;isOutput=true]$sqlChanged"
Write-Host "##vso[task.setvariable variable=TERRAFORM_CHANGED;isOutput=true]$terraformChanged"
Write-Host "##vso[task.setvariable variable=TESTS_CHANGED;isOutput=true]$testsChanged"
Write-Host "##vso[task.setvariable variable=CONFIG_CHANGED;isOutput=true]$configChanged"
Write-Host "##vso[task.setvariable variable=SCRIPTS_CHANGED;isOutput=true]$scriptsChanged"

# Determine if any deployment is needed
$deploymentNeeded = $adfChanged -or $databricksChanged -or $sqlChanged -or $terraformChanged
Write-Host "##vso[task.setvariable variable=DEPLOYMENT_NEEDED;isOutput=true]$deploymentNeeded"

Write-Host ""
if ($deploymentNeeded) {
    Write-Host "✓ Changes detected - Deployment pipeline will proceed"
} else {
    Write-Host "ℹ No deployment changes detected - Only documentation/tests modified"
}

Write-Host ""