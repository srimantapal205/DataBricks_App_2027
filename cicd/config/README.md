# CI/CD Configuration Management

## Overview

This directory contains all configuration management scripts and documentation for the CI/CD pipeline. The configuration follows a **centralized, variable-group-based approach** where all environment-specific settings are managed through Azure DevOps Library Variable Groups.

## Key Principle: Single Source of Truth 🎯

**One Place to Change Configuration** → All environment-specific parameters are stored in Azure DevOps Variable Groups. Update a value once in the variable group, and it automatically applies to all future pipeline runs.

```
Variable Groups (Azure DevOps Library)
    ↓
Pipeline Templates (cicd/templates/stages/)
    ↓
Deployments (DEV → INT → PRD)
```

## 📁 Files in This Directory

| File | Purpose | When to Use |
|------|---------|-------------|
| **variable-groups-setup.ps1** | Creates all 4 variable groups in Azure DevOps | First-time setup or re-creating variable groups |
| **VARIABLES_REFERENCE.md** | Complete documentation of all variables | Reference when looking up variable names/purposes |
| **CONFIGURATION_QUICKSTART.md** | Step-by-step setup guide | Getting started with configuration |
| **variables-template.json** | JSON template of all variables | Automation, documentation, or validation |
| **README.md** (this file) | Overview and quick links | Starting point for configuration |

## 🚀 Quick Start (3 Steps)

### 1. Run Setup Script

```powershell
cd cicd/config

.\variable-groups-setup.ps1 `
    -OrganizationUrl "https://dev.azure.com/YOUR_ORG" `
    -ProjectName "YOUR_PROJECT"
```

This creates 4 variable groups:
- `vg-shared-config` - Common settings
- `vg-dev-config` - DEV environment
- `vg-int-config` - INT environment
- `vg-prd-config` - PRD environment

### 2. Update Values in Azure DevOps

1. Go to **Azure DevOps** → **Pipelines** → **Library**
2. Open each variable group
3. Replace placeholder values with your actual values
4. Mark sensitive values as **Secret** (🔒 icon)

### 3. Test Pipeline

```bash
# Commit and push to trigger pipeline
git add .
git commit -m "Configure variable groups"
git push origin dev
```

## 📚 Documentation

### For First-Time Setup
➡️ Start here: [CONFIGURATION_QUICKSTART.md](CONFIGURATION_QUICKSTART.md)

### For Reference
➡️ Variable details: [VARIABLES_REFERENCE.md](VARIABLES_REFERENCE.md)

### For Automation
➡️ JSON template: [variables-template.json](variables-template.json)

## 🛠️ Configuration Architecture

### Variable Groups Structure

```
vg-shared-config           (Common across all environments)
├─ AZURE_SUBSCRIPTION_ID
├─ AZURE_LOCATION
├─ AZURE_TENANT_ID
├─ TF_STATE_STORAGE_ACCOUNT
├─ DATABRICKS_WORKSPACE_PATH
└─ TAG_* (tagging standards)

vg-dev-config             (DEV environment)
├─ devServiceConnection
├─ devResourceGroup
├─ DEV_ADF_NAME
├─ DEV_DATABRICKS_HOST
├─ DEV_SQL_SERVER
└─ DEV_STORAGE_ACCOUNT

vg-int-config             (INT environment)
├─ intServiceConnection
├─ intResourceGroup
├─ INT_ADF_NAME
├─ INT_DATABRICKS_HOST
├─ INT_SQL_SERVER
└─ INT_STORAGE_ACCOUNT

vg-prd-config             (PRD environment)
├─ prdServiceConnection
├─ prdResourceGroup
├─ PRD_ADF_NAME
├─ PRD_DATABRICKS_HOST
├─ PRD_SQL_SERVER
└─ PRD_STORAGE_ACCOUNT
```

### How Pipeline Uses These Variables

```yaml
# In azure-pipelines.yml

- stage: Deploy_DEV
  variables:
    - group: vg-dev-config       # ← Imports DEV variables
    - group: vg-shared-config    # ← Imports shared variables
  jobs:
    - template: templates/stages/deploy-dev.yml
      parameters:
        serviceConnection: $(devServiceConnection)  # From vg-dev-config
        resourceGroup: $(devResourceGroup)          # From vg-dev-config
        adfName: $(DEV_ADF_NAME)                   # From vg-dev-config
        location: $(AZURE_LOCATION)                 # From vg-shared-config
```

## ⚙️ Common Configuration Tasks

### Change Databricks Workspace URL (All Environments)

```bash
# Update DEV
az pipelines variable-group variable update \
    --group-id $(az pipelines variable-group list --group-name "vg-dev-config" --query "[0].id" -o tsv) \
    --name "DEV_DATABRICKS_HOST" \
    --value "https://adb-NEW-ID.azuredatabricks.net"

# Repeat for INT and PRD
```

### Change Azure Region

```bash
az pipelines variable-group variable update \
    --group-id $(az pipelines variable-group list --group-name "vg-shared-config" --query "[0].id" -o tsv) \
    --name "AZURE_LOCATION" \
    --value "westus2"
```

### Add New Variable to All Environments

```bash
for env in dev int prd; do
    az pipelines variable-group variable create \
        --group-id $(az pipelines variable-group list --group-name "vg-${env}-config" --query "[0].id" -o tsv) \
        --name "${env^^}_NEW_VARIABLE" \
        --value "VALUE"
done
```

## 🔒 Security Best Practices

### Secrets Management

1. **Identify sensitive variables**:
   - Connection strings
   - Passwords
   - API keys
   - Service principal secrets
   - Storage account keys

2. **Mark as secret in Azure DevOps**:
   - Open variable group
   - Click 🔒 lock icon next to variable
   - Variable is now encrypted

3. **Never commit secrets to Git**:
   - All secrets live in Azure DevOps Variable Groups
   - Never put secrets in YAML files

### Least Privilege Access

```
Variable Group Permissions:
✓ Build Service Account: Read
✓ Release Service Account: Read  
✓ DevOps Team: Administrator
✗ Developers: No direct access (use pipeline only)
```

## 🚦 Environment Promotion Flow

```
DEV (Automatic)           INT (Automatic)           PRD (Manual Approval)
    ↓                         ↓                         ↓
Commit to dev         ← Merge to int         ← Create release/*
    ↓                         ↓                         ↓
Uses vg-dev-config    Uses vg-int-config    Uses vg-prd-config
    ↓                         ↓                         ↓
Deploys automatically Deploys automatically Requires approval ✓
```

## 📊 Variable Naming Convention

| Pattern | Example | Usage |
|---------|---------|--------|
| `{ENV}_{SERVICE}_{PROPERTY}` | `DEV_DATABRICKS_HOST` | Environment-specific resource |
| `{env}ServiceConnection` | `devServiceConnection` | Azure service connection names |
| `{env}ResourceGroup` | `prdResourceGroup` | Resource group names |
| `TAG_{PURPOSE}` | `TAG_COST_CENTER` | Azure resource tags |
| `TF_{PURPOSE}` | `TF_STATE_STORAGE_ACCOUNT` | Terraform configuration |

**Convention Rules**:
- Environment prefix in UPPERCASE for resource names
- Environment prefix in lowercase for connection names
- Underscores for resource properties
- CamelCase for connection names

## 🛡️ Troubleshooting

### "Variable not found" Error

**Cause**: Variable group not imported in pipeline stage

**Fix**:
```yaml
variables:
  - group: vg-dev-config  # Add this line
```

### "Permission denied" Error

**Cause**: Build service lacks permission to variable group

**Fix**:
1. Library → Variable Groups → Security
2. Add `[Project] Build Service` with **Reader** role

### Variable Shows Old Value

**Cause**: Pipeline caches variables at start

**Fix**:
1. Update variable in Azure DevOps
2. **Re-run** the pipeline (don't just resume)

### Can't Update Variable via CLI

**Cause**: Not authenticated or wrong project

**Fix**:
```bash
az devops login
az devops configure --defaults \
    organization="https://dev.azure.com/YOUR_ORG" \
    project="YOUR_PROJECT"
```

## 📝 Change Management Process

### For Non-Sensitive Changes

1. Update variable in Azure DevOps Library
2. Test in DEV environment
3. If successful, apply to INT
4. If INT successful, apply to PRD

### For Sensitive Changes (connection strings, credentials)

1. Update variable in Azure DevOps Library
2. **Mark as secret** (🔒)
3. Test in DEV
4. Validate logs don't expose secret
5. Promote to INT, then PRD

### For Breaking Changes

1. Create new variable (e.g., `DEV_SQL_SERVER_V2`)
2. Update code to use new variable
3. Test thoroughly in DEV
4. Once stable, deprecate old variable
5. Promote changes through INT → PRD

## 📅 Maintenance Schedule

| Task | Frequency | Owner |
|------|-----------|--------|
| Review variable values | Monthly | DevOps Team |
| Audit secret variables | Quarterly | Security Team |
| Update documentation | Per change | DevOps Team |
| Rotate sensitive credentials | Per policy | Security Team |
| Backup variable groups | Weekly (automated) | DevOps Team |

## 🔗 Related Documentation

- [Azure Pipelines Main README](../README.md)
- [Pipeline Templates](../templates/stages/)
- [Azure DevOps Variable Groups Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups)

## ❓ FAQ

**Q: How do I add a new environment (e.g., QA)?**

A: 
1. Create new variable group `vg-qa-config`
2. Add all required variables following the pattern of existing environments
3. Add new stage in `azure-pipelines.yml`
4. Create new deployment template in `templates/stages/deploy-qa.yml`

**Q: Can I use Key Vault instead of variable groups?**

A: Yes! You can link Azure Key Vault to variable groups:
1. Library → Variable Groups → "Link secrets from an Azure key vault as variables"
2. This is recommended for production secrets

**Q: How do I backup variable groups?**

A: Use Azure DevOps CLI:
```bash
az pipelines variable-group list --output json > variable-groups-backup.json
```

**Q: Can variables reference other variables?**

A: Yes, in runtime:
```yaml
variables:
  - group: vg-dev-config
  - name: FULL_PATH
    value: '$(DEV_STORAGE_ACCOUNT)/$(DEV_DATA_LAKE_NAME)'
```

## 📞 Support

- **Issues**: Create ticket in Azure DevOps
- **Questions**: Slack #devops-support
- **Documentation**: This folder
- **Emergency**: DevOps on-call

---

**Last Updated**: 2024-01-XX  
**Maintained By**: DevOps Team  
**Version**: 1.0.0