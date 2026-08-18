# Azure DevOps Variable Groups Reference

This document provides a comprehensive reference for all variable groups used in the CI/CD pipeline. All environment-specific configuration is managed through Azure DevOps Library Variable Groups, enabling a **single source of truth** for configuration management.

## Overview

The pipeline uses **4 variable groups**:

1. **vg-shared-config** - Common configuration across all environments
2. **vg-dev-config** - DEV environment configuration
3. **vg-int-config** - INT environment configuration  
4. **vg-prd-config** - PRD environment configuration

## Configuration Management Approach

### Key Principles

1. **Single Source of Truth**: All configuration lives in Azure DevOps Variable Groups
2. **Environment Isolation**: Each environment has its own variable group
3. **No Hard-Coded Values**: Pipeline templates reference variables, never hard-coded values
4. **Easy Updates**: Change values in one place (Variable Group) and re-run the pipeline

### How It Works

```yaml
# In azure-pipelines.yml, variable groups are imported per environment
variables:
  - group: vg-dev-config      # Environment-specific
  - group: vg-shared-config   # Common across environments

# Templates then use these variables
parameters:
  serviceConnection: $(devServiceConnection)  # From vg-dev-config
  resourceGroup: $(devResourceGroup)          # From vg-dev-config
  location: $(AZURE_LOCATION)                 # From vg-shared-config
```

---

## Variable Group 1: vg-shared-config

**Purpose**: Common configuration shared across all environments

### Azure Subscription

| Variable | Description | Example |
|----------|-------------|----------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_LOCATION` | Primary Azure region | `eastus` |
| `AZURE_TENANT_ID` | Azure AD tenant ID | `87654321-4321-4321-4321-210987654321` |

### Terraform Backend

| Variable | Description | Example |
|----------|-------------|----------|
| `TF_STATE_STORAGE_ACCOUNT` | Storage account for Terraform state | `tfstatestorage` |
| `TF_STATE_CONTAINER` | Container name for Terraform state | `tfstate` |

### Databricks Common

| Variable | Description | Example |
|----------|-------------|----------|
| `DATABRICKS_WORKSPACE_PATH` | Base path for deployments | `/Shared/DataEngineering` |
| `DATABRICKS_RESOURCE_ID` | Azure Databricks resource ID | `2ff814a6-3304-4ab8-85cb-cd0e6f879c1d` |

### Naming Convention

| Variable | Description | Example |
|----------|-------------|----------|
| `PROJECT_NAME` | Project identifier | `dataeng` |
| `COMPANY_PREFIX` | Company/organization prefix | `contoso` |

### Tags

| Variable | Description | Example |
|----------|-------------|----------|
| `TAG_COST_CENTER` | Cost center for billing | `Engineering` |
| `TAG_MANAGED_BY` | Management method | `Terraform` |
| `TAG_PROJECT` | Project name | `DataEngineering` |

---

## Variable Group 2: vg-dev-config

**Purpose**: DEV environment-specific configuration

### Environment

| Variable | Description | Example |
|----------|-------------|----------|
| `ENVIRONMENT` | Full environment name | `dev` |
| `ENV_SHORT` | Environment abbreviation | `dev` |

### Azure Service Connection

| Variable | Description | Example |
|----------|-------------|----------|
| `devServiceConnection` | Azure DevOps service connection name | `azure-dev-service-connection` |
| `devResourceGroup` | Resource group name | `rg-dataeng-dev` |

### Azure Data Factory

| Variable | Description | Example |
|----------|-------------|----------|
| `DEV_ADF_NAME` | ADF instance name | `adf-dataeng-dev` |
| `DEV_ADF_RESOURCE_GROUP` | ADF resource group | `rg-dataeng-dev` |

### Databricks

| Variable | Description | Example |
|----------|-------------|----------|
| `DEV_DATABRICKS_HOST` | Databricks workspace URL | `https://adb-xxxxx.azuredatabricks.net` |
| `DEV_DATABRICKS_WORKSPACE_NAME` | Workspace name | `dbw-dataeng-dev` |
| `DEV_DATABRICKS_WORKSPACE_ID` | Full workspace resource ID | `/subscriptions/.../dbw-dataeng-dev` |

### SQL Database

| Variable | Description | Example |
|----------|-------------|----------|
| `DEV_SQL_SERVER` | SQL Server FQDN | `sql-dataeng-dev.database.windows.net` |
| `DEV_SQL_DATABASE` | Database name | `sqldb-dataeng-dev` |

### Storage

| Variable | Description | Example |
|----------|-------------|----------|
| `DEV_STORAGE_ACCOUNT` | Storage account name | `stdataengdev` |
| `DEV_DATA_LAKE_NAME` | Data lake container name | `datalake-dev` |

### Key Vault

| Variable | Description | Example |
|----------|-------------|----------|
| `DEV_KEY_VAULT_NAME` | Key Vault name | `kv-dataeng-dev` |

### Tags

| Variable | Description | Example |
|----------|-------------|----------|
| `TAG_ENVIRONMENT` | Environment tag | `Development` |

---

## Variable Group 3: vg-int-config

**Purpose**: INT environment-specific configuration

### Environment

| Variable | Description | Example |
|----------|-------------|----------|
| `ENVIRONMENT` | Full environment name | `int` |
| `ENV_SHORT` | Environment abbreviation | `int` |

### Azure Service Connection

| Variable | Description | Example |
|----------|-------------|----------|
| `intServiceConnection` | Azure DevOps service connection name | `azure-int-service-connection` |
| `intResourceGroup` | Resource group name | `rg-dataeng-int` |

### Azure Data Factory

| Variable | Description | Example |
|----------|-------------|----------|
| `INT_ADF_NAME` | ADF instance name | `adf-dataeng-int` |
| `INT_ADF_RESOURCE_GROUP` | ADF resource group | `rg-dataeng-int` |

### Databricks

| Variable | Description | Example |
|----------|-------------|----------|
| `INT_DATABRICKS_HOST` | Databricks workspace URL | `https://adb-xxxxx.azuredatabricks.net` |
| `INT_DATABRICKS_WORKSPACE_NAME` | Workspace name | `dbw-dataeng-int` |
| `INT_DATABRICKS_WORKSPACE_ID` | Full workspace resource ID | `/subscriptions/.../dbw-dataeng-int` |

### SQL Database

| Variable | Description | Example |
|----------|-------------|----------|
| `INT_SQL_SERVER` | SQL Server FQDN | `sql-dataeng-int.database.windows.net` |
| `INT_SQL_DATABASE` | Database name | `sqldb-dataeng-int` |

### Storage

| Variable | Description | Example |
|----------|-------------|----------|
| `INT_STORAGE_ACCOUNT` | Storage account name | `stdataengint` |
| `INT_DATA_LAKE_NAME` | Data lake container name | `datalake-int` |

### Key Vault

| Variable | Description | Example |
|----------|-------------|----------|
| `INT_KEY_VAULT_NAME` | Key Vault name | `kv-dataeng-int` |

### Tags

| Variable | Description | Example |
|----------|-------------|----------|
| `TAG_ENVIRONMENT` | Environment tag | `Integration` |

---

## Variable Group 4: vg-prd-config

**Purpose**: PRD (Production) environment-specific configuration

### Environment

| Variable | Description | Example |
|----------|-------------|----------|
| `ENVIRONMENT` | Full environment name | `prd` |
| `ENV_SHORT` | Environment abbreviation | `prd` |

### Azure Service Connection

| Variable | Description | Example |
|----------|-------------|----------|
| `prdServiceConnection` | Azure DevOps service connection name | `azure-prd-service-connection` |
| `prdResourceGroup` | Resource group name | `rg-dataeng-prd` |

### Azure Data Factory

| Variable | Description | Example |
|----------|-------------|----------|
| `PRD_ADF_NAME` | ADF instance name | `adf-dataeng-prd` |
| `PRD_ADF_RESOURCE_GROUP` | ADF resource group | `rg-dataeng-prd` |

### Databricks

| Variable | Description | Example |
|----------|-------------|----------|
| `PRD_DATABRICKS_HOST` | Databricks workspace URL | `https://adb-xxxxx.azuredatabricks.net` |
| `PRD_DATABRICKS_WORKSPACE_NAME` | Workspace name | `dbw-dataeng-prd` |
| `PRD_DATABRICKS_WORKSPACE_ID` | Full workspace resource ID | `/subscriptions/.../dbw-dataeng-prd` |

### SQL Database

| Variable | Description | Example |
|----------|-------------|----------|
| `PRD_SQL_SERVER` | SQL Server FQDN | `sql-dataeng-prd.database.windows.net` |
| `PRD_SQL_DATABASE` | Database name | `sqldb-dataeng-prd` |

### Storage

| Variable | Description | Example |
|----------|-------------|----------|
| `PRD_STORAGE_ACCOUNT` | Storage account name | `stdataengprd` |
| `PRD_DATA_LAKE_NAME` | Data lake container name | `datalake-prd` |

### Key Vault

| Variable | Description | Example |
|----------|-------------|----------|
| `PRD_KEY_VAULT_NAME` | Key Vault name | `kv-dataeng-prd` |

### Tags

| Variable | Description | Example |
|----------|-------------|----------|
| `TAG_ENVIRONMENT` | Environment tag | `Production` |

---

## Setup Instructions

### Step 1: Run the Setup Script

```powershell
# Navigate to the config directory
cd cicd/config

# Run the setup script
.\variable-groups-setup.ps1 `
    -OrganizationUrl "https://dev.azure.com/yourorg" `
    -ProjectName "YourProject"
```

### Step 2: Update Variable Values

1. Navigate to Azure DevOps → Pipelines → Library
2. Open each variable group
3. Update the placeholder values with your actual values
4. Save changes

### Step 3: Secure Sensitive Values

For sensitive values (passwords, secrets, tokens):

1. Click the 🔒 lock icon next to the variable
2. This makes it a "secret" variable
3. Secret variables are encrypted and not visible in logs

**Recommended secrets**:
- SQL connection strings
- API keys
- Service principal secrets

### Step 4: Set Variable Group Permissions

1. Navigate to each variable group
2. Click "Security"
3. Grant appropriate permissions:
   - **Contributors**: Read
   - **Build Service**: Read
   - **Release Service**: Read
   - **Admins**: Administrator

---

## Usage in Pipeline Templates

### Example: Using Variables in Deployment Template

```yaml
# deploy-prd.yml
parameters:
  - name: serviceConnection
    type: string
  - name: resourceGroup
    type: string

jobs:
  - task: AzureCLI@2
    inputs:
      azureSubscription: '${{ parameters.serviceConnection }}'  # Uses $(prdServiceConnection)
      scriptType: 'bash'
      inlineScript: |
        # Access other variables directly
        echo "Deploying to: $(PRD_DATABRICKS_HOST)"
        echo "ADF Name: $(PRD_ADF_NAME)"
        echo "SQL Server: $(PRD_SQL_SERVER)"
```

### Example: Stage-Level Variable Group Import

```yaml
# azure-pipelines.yml
- stage: Deploy_PRD
  variables:
    - group: vg-prd-config      # PRD-specific variables
    - group: vg-shared-config   # Shared variables
  jobs:
    - template: templates/stages/deploy-prd.yml
      parameters:
        serviceConnection: $(prdServiceConnection)
        resourceGroup: $(prdResourceGroup)
```

---

## Maintenance

### Adding New Variables

1. Update `variable-groups-setup.ps1` with the new variable
2. Run the script with `-UpdateExisting` flag:
   ```powershell
   .\variable-groups-setup.ps1 `
       -OrganizationUrl "https://dev.azure.com/yourorg" `
       -ProjectName "YourProject" `
       -UpdateExisting
   ```
3. Update this documentation

### Updating Existing Variables

**Option 1: Via Azure DevOps UI**
1. Navigate to Library → Variable Groups
2. Select the variable group
3. Edit the variable value
4. Save

**Option 2: Via Script**
1. Update the value in `variable-groups-setup.ps1`
2. Run with `-UpdateExisting` flag

### Bulk Updates

For bulk updates across environments:

```powershell
# Update all environment variable groups
$environments = @('dev', 'int', 'prd')
foreach ($env in $environments) {
    az pipelines variable-group variable update `
        --group-id $(az pipelines variable-group list --group-name "vg-$env-config" --query "[0].id" -o tsv) `
        --name "AZURE_LOCATION" `
        --value "westus2"
}
```

---

## Troubleshooting

### Variable Not Found Error

**Symptom**: Pipeline fails with "variable not found" error

**Solution**:
1. Verify variable group is linked to the pipeline stage
2. Check variable name spelling (case-sensitive)
3. Ensure variable exists in the variable group

### Permission Denied

**Symptom**: Pipeline cannot access variable group

**Solution**:
1. Go to Library → Variable Groups → Security
2. Grant "[Project] Build Service" read access
3. Grant "[Project] Release Service" read access (if using release pipelines)

### Variable Not Updating

**Symptom**: Changed variable value but pipeline uses old value

**Solution**:
1. Ensure you saved the variable group changes
2. Re-run the pipeline (variables are loaded at pipeline start)
3. Check if pipeline caching is affecting variable resolution

---

## Best Practices

### ✅ Do

- Keep all configuration in variable groups
- Use descriptive variable names
- Document all variables in this reference
- Use consistent naming conventions
- Make sensitive values secret (🔒)
- Version control the setup script
- Test variable changes in DEV first

### ❌ Don't

- Hard-code values in pipeline YAML
- Store secrets in plain text
- Use inconsistent naming across environments
- Modify variable groups without documentation
- Grant unnecessary permissions
- Skip the INT environment for testing

---

## Migration from Hard-Coded Values

If you have existing pipelines with hard-coded values:

1. **Identify all hard-coded values** in pipeline templates
2. **Add equivalent variables** to appropriate variable groups
3. **Replace hard-coded values** with variable references: `$(VARIABLE_NAME)`
4. **Test thoroughly** in DEV environment
5. **Deploy progressively** through INT, then PRD

---

## Additional Resources

- [Azure DevOps Variable Groups Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups)
- [Azure DevOps CLI Reference](https://docs.microsoft.com/en-us/cli/azure/pipelines/variable-group)
- [Pipeline Variables Syntax](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables)

---

## Change Log

| Date | Version | Changes |
|------|---------|----------|
| 2024-01-XX | 1.0 | Initial variable groups setup |

---

**Maintained by**: DevOps Team  
**Last Updated**: 2024-01-XX