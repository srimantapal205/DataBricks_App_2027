# Azure DevOps CI/CD Pipeline - Setup Guide

Complete step-by-step instructions for setting up the enterprise CI/CD pipeline.

---

## Prerequisites

Before you begin, ensure you have:

* ✓ Azure DevOps organization and project
* ✓ Azure subscription(s) for DEV, INT, and PRD
* ✓ Owner or Contributor access to Azure subscriptions
* ✓ Project Administrator access in Azure DevOps
* ✓ Git repository initialized in Azure Repos

---

## Step 1: Azure Infrastructure Setup

### 1.1 Create Resource Groups

Create resource groups for each environment:

```bash
# DEV Environment
az group create --name rg-dataeng-dev --location eastus

# INT Environment
az group create --name rg-dataeng-int --location eastus

# PRD Environment
az group create --name rg-dataeng-prd --location eastus
```

### 1.2 Create Storage Account for Terraform State

```bash
# Create storage account
az storage account create \
  --name stdataengterraform \
  --resource-group rg-dataeng-dev \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name stdataengterraform
```

### 1.3 Create Azure Key Vault

Create Key Vault for each environment:

```bash
# DEV
az keyvault create \
  --name kv-dataeng-dev \
  --resource-group rg-dataeng-dev \
  --location eastus

# INT
az keyvault create \
  --name kv-dataeng-int \
  --resource-group rg-dataeng-int \
  --location eastus

# PRD
az keyvault create \
  --name kv-dataeng-prd \
  --resource-group rg-dataeng-prd \
  --location eastus
```

---

## Step 2: Azure DevOps - Service Connections

### 2.1 Create Service Connections

Create three service connections (one per environment):

#### Navigation:
```
Azure DevOps → Project Settings → Service Connections → New Service Connection → Azure Resource Manager
```

#### Configuration for each:

**DEV Service Connection:**
* **Connection name**: `dev-service-connection`
* **Scope level**: Subscription
* **Subscription**: Select DEV subscription
* **Resource Group**: `rg-dataeng-dev`
* **Authentication**: Workload Identity Federation (recommended) or Service Principal
* **Grant access to all pipelines**: ✗ No (manually grant access)

**INT Service Connection:**
* **Connection name**: `int-service-connection`
* **Scope level**: Subscription
* **Subscription**: Select INT subscription
* **Resource Group**: `rg-dataeng-int`
* **Authentication**: Workload Identity Federation
* **Grant access to all pipelines**: ✗ No

**PRD Service Connection:**
* **Connection name**: `prd-service-connection`
* **Scope level**: Subscription
* **Subscription**: Select PRD subscription
* **Resource Group**: `rg-dataeng-prd`
* **Authentication**: Workload Identity Federation
* **Grant access to all pipelines**: ✗ No

### 2.2 Configure Service Principal Permissions

Ensure each service principal has appropriate RBAC roles:

```bash
# Get service principal ID from service connection
SP_ID="<service-principal-id>"

# Assign Contributor role
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --resource-group rg-dataeng-dev

# Assign Key Vault access
az keyvault set-policy \
  --name kv-dataeng-dev \
  --object-id $SP_ID \
  --secret-permissions get list
```

---

## Step 3: Azure DevOps - Variable Groups

### 3.1 Create Shared Variable Group

#### Navigation:
```
Pipelines → Library → + Variable Group
```

#### vg-shared-config

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `AZURE_SUBSCRIPTION_ID` | `<subscription-id>` | No |
| `AZURE_LOCATION` | `eastus` | No |
| `TF_STATE_STORAGE_ACCOUNT` | `stdataengterraform` | No |
| `TF_STATE_CONTAINER` | `tfstate` | No |

### 3.2 Create DEV Variable Group

#### vg-dev-config

| Variable Name | Value | Secret |
|---------------|-------|--------|
| `devServiceConnection` | `dev-service-connection` | No |
| `devResourceGroup` | `rg-dataeng-dev` | No |
| `DEV_ADF_NAME` | `adf-dataeng-dev` | No |
| `DEV_DATABRICKS_HOST` | `https://adb-xxx.azuredatabricks.net` | No |
| `DEV_SQL_SERVER` | `sql-dataeng-dev.database.windows.net` | No |
| `DEV_SQL_DATABASE` | `db-dataeng-dev` | No |

**Link to Key Vault:**
* Click "Link secrets from an Azure key vault"
* Select `dev-service-connection`
* Select `kv-dataeng-dev`
* Add secrets as variables

### 3.3 Create INT Variable Group

#### vg-int-config

Same structure as DEV, but with INT values.

### 3.4 Create PRD Variable Group

#### vg-prd-config

Same structure as DEV, but with PRD values.

### 3.5 Pipeline Permissions

For each variable group:
```
Variable Group → Pipeline Permissions → + Add Pipeline
```
Add: `azure-pipelines.yml`

---

## Step 4: Azure DevOps - Environments

### 4.1 Create DEV Environment

#### Navigation:
```
Pipelines → Environments → New Environment
```

#### Configuration:
* **Name**: `DEV`
* **Description**: `Development environment - automatic deployment`
* **Resource**: None (leave empty)

#### Approvals and Checks:
* No approvals required
* No checks required

### 4.2 Create INT Environment

#### Configuration:
* **Name**: `INT`
* **Description**: `Integration environment - automated testing`

#### Approvals and Checks:
* **Optional**: Add 1 approver if desired
* Otherwise, leave empty for automatic deployment

### 4.3 Create PRD Environment

#### Configuration:
* **Name**: `PRD`
* **Description**: `Production environment - requires approval`

#### Approvals and Checks:
1. Click `Approvals and checks`
2. Add `Approvals`
3. **Configuration**:
   * **Approvers**: Add at least 2 authorized production approvers
   * **Timeout**: 30 days
   * **Approval order**: Any order
   * **Minimum number of approvers**: 2
   * **Requestors cannot approve**: ✓ Checked
4. **Optional**: Add `Business hours` check
   * Restrict deployments to specific days/times

---

## Step 5: Repository Setup

### 5.1 Clone Repository

```bash
git clone https://dev.azure.com/<org>/<project>/_git/<repo>
cd <repo>
```

### 5.2 Copy Pipeline Files

Copy all files from this cicd folder to your repository root:

```bash
cp -r /path/to/cicd/* .
```

### 5.3 Update azure-pipelines.yml

Update the main pipeline file with your specifics:

```yaml
variables:
  - group: vg-shared-config
  - group: vg-dev-config
  - group: vg-int-config
  - group: vg-prd-config
```

### 5.4 Commit and Push

```bash
git add .
git commit -m "feat: add CI/CD pipeline"
git push origin main
```

---

## Step 6: Branch Structure Setup

### 6.1 Create Branches

```bash
# Create dev branch
git checkout -b dev
git push origin dev

# Create int branch
git checkout -b int
git push origin int

# Create release/prd branch
git checkout -b release/prd
git push origin release/prd

# Return to main
git checkout main
```

### 6.2 Set Default Branch

```
Repos → Branches → ... on 'dev' → Set as default branch
```

---

## Step 7: Branch Policies

### 7.1 DEV Branch Policy

#### Navigation:
```
Repos → Branches → ... on 'dev' → Branch policies
```

#### Configuration:
* **Require a minimum number of reviewers**: 1
* **Allow requestors to approve their own changes**: ✗ No
* **Prohibit the most recent pusher from approving**: ✓ Yes
* **Allow completion even if some reviewers vote to wait or reject**: ✗ No
* **When new changes are pushed**: Reset all approval votes
* **Check for linked work items**: Optional
* **Check for comment resolution**: Required
* **Limit merge types**: Squash merge only (recommended)

#### Build Validation:
```
Add build policy:
  Build pipeline: azure-pipelines.yml
  Path filter: (leave empty)
  Trigger: Automatic
  Policy requirement: Required
  Build expiration: Immediately
  Display name: CI Validation
```

### 7.2 INT Branch Policy

Same as DEV.

### 7.3 PRD Branch Policy

#### Configuration:
* **Require a minimum number of reviewers**: **2**
* **Require at least one reviewer to be from authorized group**: ✓ Yes (add production approvers group)
* **Prohibit the most recent pusher from approving**: ✓ Yes
* **Check for linked work items**: Required
* **Check for comment resolution**: Required
* All other settings stricter than DEV

---

## Step 8: Create Pipeline in Azure DevOps

### 8.1 Create Pipeline

#### Navigation:
```
Pipelines → Pipelines → New Pipeline
```

#### Configuration:
1. **Where is your code?**: Azure Repos Git
2. **Select a repository**: Your repository
3. **Configure your pipeline**: Existing Azure Pipelines YAML file
4. **Select an existing YAML file**:
   * Branch: `dev`
   * Path: `/azure-pipelines.yml`
5. **Review**: Review the YAML
6. **Save**: Save (don't run yet)

### 8.2 Grant Pipeline Permissions

Grant the pipeline access to:
* Service connections (all three)
* Variable groups (all four)
* Environments (DEV, INT, PRD)

### 8.3 Rename Pipeline

```
Pipeline → ... (three dots) → Rename/move
New name: Data Engineering CI/CD
```

---

## Step 9: Test the Pipeline

### 9.1 Create Test Feature Branch

```bash
git checkout dev
git checkout -b feature/test-pipeline

# Make a simple change
echo "# Test" >> test.txt

git add test.txt
git commit -m "test: pipeline setup"
git push origin feature/test-pipeline
```

### 9.2 Create Pull Request

1. Navigate to Azure DevOps Repos
2. Create PR: `feature/test-pipeline` → `dev`
3. Observe:
   * Branch policy validation triggers
   * CI pipeline runs
   * Change detection works
   * Validation passes

### 9.3 Merge and Monitor

1. After CI passes, merge the PR
2. Observe:
   * Pipeline triggers on `dev` branch
   * Change detection runs
   * Artifacts built
   * DEV deployment occurs

---

## Step 10: Configure Notifications (Optional)

### 10.1 Pipeline Notifications

```
Project Settings → Notifications → New subscription
```

#### Recommended Notifications:

**Build Completion:**
* **Event**: Build completes
* **Filter**: Only failed builds
* **Recipients**: Team email

**Deployment Approval Pending:**
* **Event**: Approval pending
* **Filter**: PRD environment
* **Recipients**: Production approvers

**Deployment Completion:**
* **Event**: Deployment completes
* **Filter**: All environments
* **Recipients**: Team email

### 10.2 Repository Notifications

```
Repos → Settings → Notifications → New subscription
```

**Pull Request Created:**
* **Event**: Pull request created
* **Filter**: All branches
* **Recipients**: Team email

---

## Step 11: Security Hardening

### 11.1 Enable Azure DevOps Security Features

```
Organization Settings → Policies
```

* ✓ Disable creation of classic build pipelines
* ✓ Disable creation of classic release pipelines
* ✓ Limit variables that can be set at queue time
* ✓ Limit job authorization scope to current project
* ✓ Protect access to repositories in YAML pipelines

### 11.2 Review RBAC

Ensure proper role assignments:

```
Project Settings → Permissions
```

* **Build Administrators**: DevOps team only
* **Contributors**: Development team
* **Readers**: Stakeholders
* **Release Administrators**: Separate from developers

### 11.3 Configure Key Vault Policies

```bash
# Ensure pipeline service principals have minimal permissions
az keyvault set-policy \
  --name kv-dataeng-prd \
  --object-id <prd-sp-id> \
  --secret-permissions get list
```

---

## Step 12: Documentation

### 12.1 Update README

Update the main README.md with:
* Project-specific information
* Team contacts
* Additional setup steps

### 12.2 Create Runbooks

Create runbooks in `docs/` for:
* Emergency procedures
* Rollback procedures
* Troubleshooting guide
* On-call escalation

---

## Validation Checklist

Before going live, verify:

* ☐ All service connections created and working
* ☐ All variable groups created and linked
* ☐ All environments created with proper approvals
* ☐ Branch policies configured on all protected branches
* ☐ Pipeline runs successfully on feature branch
* ☐ DEV deployment works
* ☐ INT deployment works
* ☐ PRD approval gate works
* ☐ Secrets are NOT in Git
* ☐ Key Vault integration working
* ☐ Notifications configured
* ☐ Team trained on workflow
* ☐ Documentation complete

---

## Troubleshooting

### Pipeline Fails to Trigger
* Check branch trigger configuration in `azure-pipelines.yml`
* Verify branch policy build validation is configured
* Check pipeline permissions

### Service Connection Fails
* Verify service principal has correct RBAC roles
* Check subscription ID is correct
* Verify resource group exists
* Test connection in Azure DevOps

### Variable Group Not Available
* Check pipeline has permission to use variable group
* Verify variable group linked to correct Key Vault
* Check service connection has Key Vault access

### Environment Approval Not Triggered
* Verify environment name matches YAML
* Check approval policy is configured
* Ensure approvers have correct permissions

---

## Next Steps

After setup:

1. ✓ Train team on Git workflow
2. ✓ Conduct test deployment to all environments
3. ✓ Document any custom procedures
4. ✓ Set up monitoring and alerts
5. ✓ Schedule regular pipeline reviews

---

**Setup Complete!** 🎉

You now have a production-grade CI/CD pipeline ready for Azure data engineering workloads.