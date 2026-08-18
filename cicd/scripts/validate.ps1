# ============================================================================
# Validation Script
# ============================================================================
# Comprehensive validation for all components
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'adf', 'databricks', 'sql', 'terraform', 'python')]
    [string]$Component = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$Path = '.'
)

Write-Host "============================================"
Write-Host "Component Validation"
Write-Host "============================================"
Write-Host "Component: $Component"
Write-Host "Path:      $Path"
Write-Host "============================================"

$exitCode = 0

# ============================================================================
# Function: Validate ADF
# ============================================================================
function Validate-ADF {
    Write-Host ""
    Write-Host "Validating Azure Data Factory..."
    Write-Host "-----------------------------------"
    
    if (Test-Path "$Path/adf") {
        $jsonFiles = Get-ChildItem -Path "$Path/adf" -Filter *.json -Recurse
        
        foreach ($file in $jsonFiles) {
            Write-Host "Validating: $($file.FullName)"
            try {
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                Write-Host "  ✓ Valid JSON"
            } catch {
                Write-Host "  ✗ Invalid JSON: $_" -ForegroundColor Red
                $script:exitCode = 1
            }
        }
        
        Write-Host "✓ ADF validation completed"
    } else {
        Write-Host "No ADF directory found - Skipping"
    }
}

# ============================================================================
# Function: Validate Databricks
# ============================================================================
function Validate-Databricks {
    Write-Host ""
    Write-Host "Validating Databricks assets..."
    Write-Host "-----------------------------------"
    
    if (Test-Path "$Path/databricks") {
        # Validate Python notebooks
        $pyFiles = Get-ChildItem -Path "$Path/databricks" -Filter *.py -Recurse
        
        foreach ($file in $pyFiles) {
            Write-Host "Validating: $($file.FullName)"
            python -m py_compile $file.FullName 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Valid Python syntax"
            } else {
                Write-Host "  ✗ Python syntax error" -ForegroundColor Red
                $script:exitCode = 1
            }
        }
        
        # Validate workflow JSON files
        $workflowFiles = Get-ChildItem -Path "$Path/databricks/workflows" -Filter *.json -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $workflowFiles) {
            Write-Host "Validating workflow: $($file.FullName)"
            try {
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                Write-Host "  ✓ Valid workflow JSON"
            } catch {
                Write-Host "  ✗ Invalid workflow JSON: $_" -ForegroundColor Red
                $script:exitCode = 1
            }
        }
        
        Write-Host "✓ Databricks validation completed"
    } else {
        Write-Host "No Databricks directory found - Skipping"
    }
}

# ============================================================================
# Function: Validate SQL
# ============================================================================
function Validate-SQL {
    Write-Host ""
    Write-Host "Validating SQL scripts..."
    Write-Host "-----------------------------------"
    
    if (Test-Path "$Path/sql") {
        $sqlFiles = Get-ChildItem -Path "$Path/sql" -Filter *.sql -Recurse
        
        foreach ($file in $sqlFiles) {
            Write-Host "Validating: $($file.FullName)"
            
            # Basic SQL validation
            $content = Get-Content $file.FullName -Raw
            
            # Check for basic syntax issues
            if ($content -match "^\s*$") {
                Write-Host "  ✗ Empty SQL file" -ForegroundColor Yellow
            } else {
                Write-Host "  ✓ SQL file contains content"
            }
        }
        
        Write-Host "✓ SQL validation completed"
    } else {
        Write-Host "No SQL directory found - Skipping"
    }
}

# ============================================================================
# Function: Validate Terraform
# ============================================================================
function Validate-Terraform {
    Write-Host ""
    Write-Host "Validating Terraform infrastructure..."
    Write-Host "-----------------------------------"
    
    if (Test-Path "$Path/infrastructure/terraform") {
        Push-Location "$Path/infrastructure/terraform"
        
        # Terraform format check
        Write-Host "Running terraform fmt..."
        terraform fmt -check -recursive
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ✗ Terraform formatting issues found" -ForegroundColor Yellow
        } else {
            Write-Host "  ✓ Terraform formatting correct"
        }
        
        # Validate each environment
        foreach ($env in @('dev', 'int', 'prd')) {
            $envPath = "environments/$env"
            if (Test-Path $envPath) {
                Write-Host ""
                Write-Host "Validating environment: $env"
                Push-Location $envPath
                
                terraform init -backend=false | Out-Null
                terraform validate
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ $env environment valid"
                } else {
                    Write-Host "  ✗ $env environment validation failed" -ForegroundColor Red
                    $script:exitCode = 1
                }
                
                Pop-Location
            }
        }
        
        Pop-Location
        Write-Host "✓ Terraform validation completed"
    } else {
        Write-Host "No Terraform directory found - Skipping"
    }
}

# ============================================================================
# Function: Validate Python
# ============================================================================
function Validate-Python {
    Write-Host ""
    Write-Host "Validating Python code..."
    Write-Host "-----------------------------------"
    
    $pyFiles = Get-ChildItem -Path $Path -Filter *.py -Recurse | Where-Object { $_.FullName -notmatch '\\.venv\\|\\venv\\|__pycache__|.pyc$' }
    
    foreach ($file in $pyFiles) {
        Write-Host "Linting: $($file.FullName)"
        
        # Python syntax check
        python -m py_compile $file.FullName 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Valid Python syntax"
        } else {
            Write-Host "  ✗ Python syntax error" -ForegroundColor Red
            $script:exitCode = 1
        }
    }
    
    Write-Host "✓ Python validation completed"
}

# ============================================================================
# Execute Validation
# ============================================================================

switch ($Component) {
    'adf' {
        Validate-ADF
    }
    'databricks' {
        Validate-Databricks
    }
    'sql' {
        Validate-SQL
    }
    'terraform' {
        Validate-Terraform
    }
    'python' {
        Validate-Python
    }
    'all' {
        Validate-ADF
        Validate-Databricks
        Validate-SQL
        Validate-Terraform
        Validate-Python
    }
}

Write-Host ""
Write-Host "============================================"
if ($exitCode -eq 0) {
    Write-Host "✓ All validations passed" -ForegroundColor Green
} else {
    Write-Host "✗ Validation failed" -ForegroundColor Red
}
Write-Host "============================================"

exit $exitCode