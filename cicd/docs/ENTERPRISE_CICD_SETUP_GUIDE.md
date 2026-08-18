# Enterprise CI/CD Setup Guide
## Large-Scale Databricks Application with Azure DevOps

---

## 📋 Document Overview

**Purpose**: Complete step-by-step guide for setting up enterprise-grade CI/CD for a large-scale Databricks application

**Key Features**:
- Azure DevOps Git integration
- Dynamic configuration using Library Variable Groups
- Change-based deployment strategy
- Self-hosted VM agents
- Service Principal with Federated Identity (Workload Identity Federation)
- Terraform infrastructure as code
- Multi-environment deployment (DEV → INT → PRD)

**Target Audience**: DevOps Engineers, Platform Engineers, Cloud Architects

**Estimated Setup Time**: 4-6 hours

---

## Table of Contents

1. [Prerequisites & Requirements](#1-prerequisites--requirements)
2. [Architecture Overview](#2-architecture-overview)
3. [Azure Setup](#3-azure-setup)
   - 3.1. [Service Principal with Federated Identity](#31-service-principal-with-federated-identity)
   - 3.2. [Resource Groups & Permissions](#32-resource-groups--permissions)
4. [Self-Hosted Agent Setup](#4-self-hosted-agent-setup)
5. [Azure DevOps Configuration](#5-azure-devops-configuration)
   - 5.1. [Project Setup](#51-project-setup)
   - 5.2. [Variable Groups](#52-variable-groups)
   - 5.3. [Service Connections](#53-service-connections)
   - 5.4. [Agent Pools](#54-agent-pools)
6. [Terraform Configuration](#6-terraform-configuration)
7. [Change-Based Deployment Strategy](#7-change-based-deployment-strategy)
8. [CI/CD Pipeline Setup](#8-cicd-pipeline-setup)
9. [Testing & Validation](#9-testing--validation)
10. [Monitoring & Troubleshooting](#10-monitoring--troubleshooting)
11. [Security Best Practices](#11-security-best-practices)
12. [Appendix](#12-appendix)

---

## 1. Prerequisites & Requirements

### 1.1 Azure Subscription Requirements

✅ **Required Permissions**:
- Subscription Contributor or Owner
- Azure AD Application Administrator (for Service Principal creation)
- Ability to create Resource Groups
- Access to create Managed Identities

✅ **Azure Services Needed**:
- Azure Databricks Workspace (Premium tier recommended)
- Azure Data Factory
- Azure SQL Database
- Azure Storage Accounts (for data lake & Terraform state)
- Azure Key Vault
- Azure Virtual Machine (for self-hosted agent)

### 1.2 Azure DevOps Requirements

✅ **Organization & Project**:
- Azure DevOps organization created
- Project with appropriate permissions
- Basic + Test Plans license (or higher)

✅ **Required Extensions**:
- Terraform extension
- Azure Databricks extension (if available)
- Replace Tokens extension (optional)

### 1.3 Software Requirements

✅ **On Self-Hosted VM**:
- Ubuntu 20.04 LTS or Windows Server 2019/2022
- Azure DevOps Agent (latest version)
- Azure CLI (v2.50+)
- Terraform (v1.5+)
- Python 3.10+
- PowerShell 7+
- Databricks CLI
- Git

✅ **On Developer Workstation**:
- Azure CLI
- Azure DevOps CLI extension
- Terraform
- Git
- VS Code (recommended)

### 1.4 Access Requirements

✅ **Accounts & Credentials**:
- Azure subscription credentials
- Azure DevOps organization access
- GitHub/Azure Repos access
- Databricks workspace admin access

---

## 2. Architecture Overview

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure DevOps Organization                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌──────────────────┐   ┌───────────────┐  │
│  │   Git Repo  │───▶│  CI/CD Pipeline  │──▶│ Self-Hosted   │  │
│  │             │    │                  │   │ Agent Pool    │  │
│  └─────────────┘    └──────────────────┘   └───────┬───────┘  │
│                              │                      │          │
│  ┌──────────────────────────┴──────────────────────┘          │
│  │                                                             │
│  │  ┌────────────────────┐      ┌──────────────────────┐     │
│  │  │ Variable Groups    │      │ Service Connections  │     │
│  │  │ (Dynamic Config)   │      │ (Federated Identity) │     │
│  │  └────────────────────┘      └──────────────────────┘     │
│  │                                                             │
└──┼─────────────────────────────────────────────────────────────┘
   │
   │  Change Detection
   │  ─────────────────────────────────────────────────
   ▼
┌──────────────────────────────────────────────────────────────┐
│                      Deployment Flow                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐   ┌──────────┐   ┌───────────┐              │
│  │ Terraform│──▶│   ADF    │──▶│Databricks │              │
│  │  (IaC)   │   │          │   │           │              │
│  └──────────┘   └──────────┘   └───────────┘              │
│                                                              │
│  Deployed to:                                                │
│  • DEV Environment (Automatic)                               │
│  • INT Environment (Automatic after DEV)                     │
│  • PRD Environment (Manual Approval)                         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Workload Identity Federation Flow              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Azure DevOps Pipeline                                      │
│       │                                                     │
│       │ (1) Request token with federated credential         │
│       ▼                                                     │
│  Azure AD                                                   │
│       │                                                     │
│       │ (2) Validate trust & issue token                    │
│       ▼                                                     │
│  Service Principal                                          │
│       │                                                     │
│       │ (3) Authenticate to Azure Resources                 │
│       ▼                                                     │
│  Azure Resources (Databricks, ADF, Storage, etc.)          │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Benefits:
✓ No secrets in pipeline
✓ Automatic token rotation
✓ Granular RBAC control
✓ Audit trail
```

### 2.3 Change-Based Deployment Strategy

```
Commit to Git
     │
     ▼
┌─────────────────┐
│ Change Detection│  ◄── Scans changed files
└────────┬────────┘
         │
         ├─── ADF Changed? ────▶ Deploy ADF
         ├─── Databricks? ──────▶ Deploy Notebooks
         ├─── Terraform? ───────▶ Deploy Infrastructure
         └─── SQL Changed? ─────▶ Deploy SQL Scripts

Only changed components are deployed ✓
```

---

## 3. Azure Setup

### 3.1 Service Principal with Federated Identity

#### Step 3.1.1: Create Service Principal

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create Service Principal (without secret)
az ad sp create-for-rbac \
    --name "sp-databricks-cicd-dev" \
    --role "Contributor" \
    --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-databricks-dev" \
    --skip-assignment

# Note the output:
# - appId (Application ID)
# - tenant (Tenant ID)
```

**Repeat for INT and PRD environments**:
```bash
az ad sp create-for-rbac --name "sp-databricks-cicd-int" ...
az ad sp create-for-rbac --name "sp-databricks-cicd-prd" ...
```

#### Step 3.1.2: Configure Federated Identity Credential

```bash
# Get Azure DevOps organization and project details
ADO_ORG="your-org-name"
ADO_PROJECT="your-project-name"
APP_ID="<appId from previous step>"

# Create federated credential for DEV
az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
        'name': 'azure-devops-dev-pipeline',
        'issuer': 'https://vstoken.dev.azure.com/<AZURE_DEVOPS_ORG_ID>',
        'subject': 'sc://${ADO_ORG}/${ADO_PROJECT}/azure-dev-service-connection',
        'audiences': ['api://AzureADTokenExchange'],
        'description': 'Federated identity for DEV pipeline'
    }"
```

**Finding your Azure DevOps Organization ID**:
```bash
# Using Azure DevOps CLI
az devops project show \
    --organization "https://dev.azure.com/${ADO_ORG}" \
    --project "${ADO_PROJECT}" \
    --query id -o tsv
```

#### Step 3.1.3: Assign RBAC Permissions

```bash
# Assign Contributor role on Resource Group
az role assignment create \
    --assignee $APP_ID \
    --role "Contributor" \
    --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-databricks-dev"

# Assign Databricks Contributor role
az role assignment create \
    --assignee $APP_ID \
    --role "Contributor" \
    --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-databricks-dev/providers/Microsoft.Databricks/workspaces/dbw-dev"

# Assign Data Factory Contributor
az role assignment create \
    --assignee $APP_ID \
    --role "Data Factory Contributor" \
    --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-databricks-dev/providers/Microsoft.DataFactory/factories/adf-dev"

# Assign Key Vault access
az keyvault set-policy \
    --name "kv-databricks-dev" \
    --spn $APP_ID \
    --secret-permissions get list \
    --key-permissions get list
```

#### Step 3.1.4: Verify Service Principal

```bash
# List service principal details
az ad sp show --id $APP_ID

# List role assignments
az role assignment list --assignee $APP_ID --output table

# List federated credentials
az ad app federated-credential list --id $APP_ID
```

### 3.2 Resource Groups & Permissions

#### Step 3.2.1: Create Resource Groups

```bash
# DEV Environment
az group create \
    --name "rg-databricks-dev" \
    --location "eastus" \
    --tags Environment=DEV Project=DataEngineering ManagedBy=Terraform

# INT Environment
az group create \
    --name "rg-databricks-int" \
    --location "eastus" \
    --tags Environment=INT Project=DataEngineering ManagedBy=Terraform

# PRD Environment
az group create \
    --name "rg-databricks-prd" \
    --location "eastus" \
    --tags Environment=PRD Project=DataEngineering ManagedBy=Terraform

# Terraform State Resource Group
az group create \
    --name "rg-terraform-state" \
    --location "eastus" \
    --tags Purpose=TerraformState Project=DataEngineering
```

#### Step 3.2.2: Create Terraform State Storage

```bash
# Create storage account for Terraform state
az storage account create \
    --name "sttfstate${RANDOM}" \
    --resource-group "rg-terraform-state" \
    --location "eastus" \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2

# Create container for Terraform state files
az storage container create \
    --name "tfstate" \
    --account-name "sttfstate${RANDOM}" \
    --auth-mode login

# Enable versioning (recommended)
az storage account blob-service-properties update \
    --account-name "sttfstate${RANDOM}" \
    --enable-versioning true

# Enable soft delete
az storage account blob-service-properties update \
    --account-name "sttfstate${RANDOM}" \
    --enable-delete-retention true \
    --delete-retention-days 30
```

---

## 4. Self-Hosted Agent Setup

### 4.1 Create VM for Self-Hosted Agent

#### Step 4.1.1: Create VM

```bash
# Create VM for DEV agent
az vm create \
    --resource-group "rg-databricks-dev" \
    --name "vm-azdo-agent-dev" \
    --image "UbuntuLTS" \
    --size "Standard_D4s_v3" \
    --admin-username "azureuser" \
    --generate-ssh-keys \
    --public-ip-address-dns-name "azdo-agent-dev-${RANDOM}" \
    --nsg-rule SSH \
    --tags Purpose=AzureDevOpsAgent Environment=DEV

# Get VM public IP
VM_IP=$(az vm show -d \
    --resource-group "rg-databricks-dev" \
    --name "vm-azdo-agent-dev" \
    --query publicIps -o tsv)

echo "VM Public IP: $VM_IP"
```

#### Step 4.1.2: Configure VM

SSH into the VM:
```bash
ssh azureuser@$VM_IP
```

Run the following setup script:

```bash
#!/bin/bash

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    software-properties-common \
    unzip \
    jq

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform

# Install Python 3.10
sudo apt-get install -y python3.10 python3.10-venv python3-pip

# Install PowerShell
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Install Databricks CLI
pip3 install databricks-cli

# Install Node.js (for ADF deployment)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker (optional, for containerized builds)
sudo apt-get install -y docker.io
sudo usermod -aG docker azureuser

# Verify installations
az --version
terraform --version
python3 --version
pwsh --version
databricks --version
node --version

echo "VM setup complete!"
```

### 4.2 Install Azure DevOps Agent

#### Step 4.2.1: Download Agent

```bash
# Create agent directory
mkdir -p ~/azdo-agent && cd ~/azdo-agent

# Download latest agent
wget https://vstsagentpackage.azureedge.net/agent/3.232.3/vsts-agent-linux-x64-3.232.3.tar.gz

# Extract
tar zxvf vsts-agent-linux-x64-3.232.3.tar.gz
```

#### Step 4.2.2: Configure Agent

```bash
# Configure agent
./config.sh

# You'll be prompted for:
# - Server URL: https://dev.azure.com/YOUR_ORG
# - Authentication type: PAT
# - Personal Access Token: (Generate from Azure DevOps)
# - Agent pool: (e.g., "Self-Hosted-DEV")
# - Agent name: (e.g., "vm-azdo-agent-dev")
# - Work folder: (_work)
# - Run as service: Y
```

**Generating PAT in Azure DevOps**:
1. Go to Azure DevOps → User Settings → Personal Access Tokens
2. Click "New Token"
3. Name: "Self-Hosted Agent - DEV"
4. Scopes: **Agent Pools (Read & Manage)**
5. Copy the token (you won't see it again!)

#### Step 4.2.3: Install and Start Service

```bash
# Install service
sudo ./svc.sh install

# Start service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status

# View logs
tail -f _diag/*.log
```

#### Step 4.2.4: Verify Agent Registration

1. Go to Azure DevOps → Project Settings → Agent pools
2. Select your pool (e.g., "Self-Hosted-DEV")
3. Verify agent appears with green "Online" status

### 4.3 Configure Managed Identity (Optional but Recommended)

```bash
# Assign system-assigned managed identity to VM
az vm identity assign \
    --resource-group "rg-databricks-dev" \
    --name "vm-azdo-agent-dev"

# Get managed identity principal ID
MI_PRINCIPAL_ID=$(az vm show \
    --resource-group "rg-databricks-dev" \
    --name "vm-azdo-agent-dev" \
    --query identity.principalId -o tsv)

# Assign roles to managed identity
az role assignment create \
    --assignee $MI_PRINCIPAL_ID \
    --role "Reader" \
    --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-databricks-dev"

# Allow VM to read Key Vault secrets
az keyvault set-policy \
    --name "kv-databricks-dev" \
    --object-id $MI_PRINCIPAL_ID \
    --secret-permissions get list
```

---

## 5. Azure DevOps Configuration

### 5.1 Project Setup

#### Step 5.1.1: Create Project

1. Navigate to Azure DevOps: `https://dev.azure.com/YOUR_ORG`
2. Click "+ New Project"
3. Project name: `Databricks-Enterprise-Platform`
4. Visibility: Private
5. Version control: Git
6. Work item process: Agile
7. Click "Create"

#### Step 5.1.2: Initialize Repository

```bash
# Clone repository
git clone https://dev.azure.com/YOUR_ORG/Databricks-Enterprise-Platform/_git/Databricks-Enterprise-Platform

cd Databricks-Enterprise-Platform

# Create branch structure
git checkout -b dev
git push origin dev

git checkout -b int
git push origin int

git checkout -b release/prd
git push origin release/prd

# Set default branch to 'dev'
# (Do this in Azure DevOps UI: Repos → Branches → Set as default)
```

#### Step 5.1.3: Configure Branch Policies

**For 'dev' branch**:
1. Repos → Branches → dev → Branch policies
2. Enable:
   - ☑ Require a minimum number of reviewers: 1
   - ☑ Check for linked work items
   - ☑ Check for comment resolution
   - ☑ Build validation (select CI pipeline)

**For 'int' and 'release/prd' branches**:
- Same as dev, but require 2 reviewers

### 5.2 Variable Groups

#### Step 5.2.1: Create Variable Groups via Script

Use the script from `cicd/config/variable-groups-setup.ps1` (already created):

```powershell
.\variable-groups-setup.ps1 `
    -OrganizationUrl "https://dev.azure.com/YOUR_ORG" `
    -ProjectName "Databricks-Enterprise-Platform"
```

#### Step 5.2.2: Add Self-Hosted Agent Variables

Add these variables to each environment variable group:

**vg-dev-config**:
```yaml
AGENT_POOL: "Self-Hosted-DEV"
AGENT_WORKSPACE: "/home/azureuser/azdo-agent/_work"
VM_RESOURCE_ID: "/subscriptions/.../resourceGroups/rg-databricks-dev/providers/Microsoft.Compute/virtualMachines/vm-azdo-agent-dev"
```

**vg-int-config** and **vg-prd-config**: Similar structure

#### Step 5.2.3: Link Key Vault to Variable Groups (Recommended)

1. Go to Pipelines → Library → Variable Groups
2. Select a variable group (e.g., "vg-dev-config")
3. Click "Link secrets from an Azure key vault as variables"
4. Select your Azure subscription
5. Select Key Vault (e.g., "kv-databricks-dev")
6. Authorize
7. Select secrets to import
8. Save

### 5.3 Service Connections

#### Step 5.3.1: Create Service Connection with Federated Identity

**Manual Method (Azure DevOps UI)**:

1. Project Settings → Service connections → New service connection
2. Select "Azure Resource Manager"
3. Authentication method: **"Workload Identity federation (automatic)"**
4. Subscription: Select your subscription
5. Resource group: Select DEV resource group
6. Service connection name: `azure-dev-service-connection`
7. Grant access permission to all pipelines: ☑
8. Click "Save"

**Automated Method (Azure CLI)**:

```bash
# Set variables
ADO_ORG="your-org"
ADO_PROJECT="Databricks-Enterprise-Platform"
SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
SUBSCRIPTION_NAME="YOUR_SUBSCRIPTION_NAME"
RG_NAME="rg-databricks-dev"
SP_APP_ID="<Your Service Principal App ID>"
SP_TENANT_ID="<Your Tenant ID>"

# Configure Azure DevOps CLI
az devops configure --defaults \
    organization="https://dev.azure.com/${ADO_ORG}" \
    project="${ADO_PROJECT}"

# Create service endpoint
az devops service-endpoint azurerm create \
    --name "azure-dev-service-connection" \
    --azure-rm-service-principal-id "$SP_APP_ID" \
    --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
    --azure-rm-tenant-id "$SP_TENANT_ID" \
    --azure-rm-service-principal-certificate-path "" \
    --org "https://dev.azure.com/${ADO_ORG}" \
    --project "${ADO_PROJECT}"
```

**Repeat for INT and PRD**:
- `azure-int-service-connection`
- `azure-prd-service-connection`

#### Step 5.3.2: Configure Service Connection for Federated Auth

1. Go to Project Settings → Service connections
2. Select the service connection
3. Click "Edit"
4. Under "Authentication", verify it shows "Workload Identity federation"
5. Note the Service Connection ID (needed for federated credential)

#### Step 5.3.3: Update Federated Credential Subject

Update the federated credential created earlier:

```bash
# Get service connection ID
SC_ID=$(az devops service-endpoint list \
    --query "[?name=='azure-dev-service-connection'].id" -o tsv)

# Update federated credential with correct subject
az ad app federated-credential update \
    --id $APP_ID \
    --federated-credential-id "azure-devops-dev-pipeline" \
    --parameters "{
        'subject': 'sc://${ADO_ORG}/${ADO_PROJECT}/${SC_ID}'
    }"
```

### 5.4 Agent Pools

#### Step 5.4.1: Create Agent Pools

1. Project Settings → Agent pools → Add pool
2. Pool type: Self-hosted
3. Name: `Self-Hosted-DEV`
4. Grant access permission to all pipelines: ☑
5. Click "Create"

**Repeat for**:
- `Self-Hosted-INT`
- `Self-Hosted-PRD`

#### Step 5.4.2: Configure Pool Permissions

1. Select agent pool → Security
2. Add:
   - **Build Service Account**: User (for running jobs)
   - **Project Administrators**: Administrator
   - **Contributors**: Reader

---

## 6. Terraform Configuration

### 6.1 Terraform Directory Structure

Create this structure in your repository:

```
infrastructure/
└── terraform/
    ├── modules/
    │   ├── databricks/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── adf/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   ├── storage/
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── networking/
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    ├── environments/
    │   ├── dev/
    │   │   ├── main.tf
    │   │   ├── backend.tf
    │   │   ├── terraform.tfvars
    │   │   └── variables.tf
    │   ├── int/
    │   │   └── ...
    │   └── prd/
    │       └── ...
    └── shared/
        ├── variables.tf
        └── providers.tf
```

### 6.2 Backend Configuration

Create `infrastructure/terraform/environments/dev/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstateXXXXX"  # Replace with your storage account
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}
```

### 6.3 Provider Configuration

Create `infrastructure/terraform/shared/providers.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.28.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  
  # Use workload identity federation
  use_oidc = true
}

provider "databricks" {
  host = var.databricks_host
  # Azure authentication via Azure CLI or Managed Identity
  azure_workspace_resource_id = var.databricks_workspace_id
}
```

### 6.4 Main Terraform Configuration

Create `infrastructure/terraform/environments/dev/main.tf`:

```hcl
module "databricks" {
  source = "../../modules/databricks"
  
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  
  workspace_name = var.databricks_workspace_name
  sku            = "premium"
  
  tags = var.tags
}

module "adf" {
  source = "../../modules/adf"
  
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  
  data_factory_name = var.adf_name
  
  tags = var.tags
}

module "storage" {
  source = "../../modules/storage"
  
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  
  storage_account_name = var.storage_account_name
  
  tags = var.tags
}
```

### 6.5 Variables File

Create `infrastructure/terraform/environments/dev/terraform.tfvars`:

```hcl
environment         = "dev"
resource_group_name = "rg-databricks-dev"
location            = "eastus"

databricks_workspace_name = "dbw-dataeng-dev"
adf_name                  = "adf-dataeng-dev"
storage_account_name      = "stdataengdev"

tags = {
  Environment = "Development"
  Project     = "DataEngineering"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
```

---

## 7. Change-Based Deployment Strategy

### 7.1 Change Detection Script

Create `cicd/scripts/detect-changes.sh`:

```bash
#!/bin/bash

# Detect which components have changed

echo "Detecting changes between $SOURCE_BRANCH and $TARGET_BRANCH"

# Get list of changed files
CHANGED_FILES=$(git diff --name-only $SOURCE_BRANCH $TARGET_BRANCH)

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Check for Terraform changes
if echo "$CHANGED_FILES" | grep -q "^infrastructure/terraform/"; then
    echo "##vso[task.setvariable variable=TERRAFORM_CHANGED;isOutput=true]true"
    echo "✓ Terraform changes detected"
else
    echo "##vso[task.setvariable variable=TERRAFORM_CHANGED;isOutput=true]false"
fi

# Check for ADF changes
if echo "$CHANGED_FILES" | grep -q "^adf/"; then
    echo "##vso[task.setvariable variable=ADF_CHANGED;isOutput=true]true"
    echo "✓ ADF changes detected"
else
    echo "##vso[task.setvariable variable=ADF_CHANGED;isOutput=true]false"
fi

# Check for Databricks changes
if echo "$CHANGED_FILES" | grep -q "^databricks/"; then
    echo "##vso[task.setvariable variable=DATABRICKS_CHANGED;isOutput=true]true"
    echo "✓ Databricks changes detected"
else
    echo "##vso[task.setvariable variable=DATABRICKS_CHANGED;isOutput=true]false"
fi

# Check for SQL changes
if echo "$CHANGED_FILES" | grep -q "^sql/"; then
    echo "##vso[task.setvariable variable=SQL_CHANGED;isOutput=true]true"
    echo "✓ SQL changes detected"
else
    echo "##vso[task.setvariable variable=SQL_CHANGED;isOutput=true]false"
fi

echo ""
echo "Change detection complete!"
```

Make executable:
```bash
chmod +x cicd/scripts/detect-changes.sh
```

### 7.2 Change-Based Pipeline Template

Update `cicd/templates/stages/deploy-dev.yml` to use change detection:

```yaml
- job: DeployTerraform
  displayName: 'Deploy Terraform Infrastructure'
  condition: eq(variables['TERRAFORM_CHANGED'], 'true')  # Only if Terraform changed
  pool:
    name: $(AGENT_POOL)  # Use self-hosted agent
  steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform'
      inputs:
        terraformVersion: 'latest'
    
    - task: TerraformTaskV4@4
      displayName: 'Terraform Init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(System.DefaultWorkingDirectory)/infrastructure/terraform/environments/dev'
        backendServiceArm: '$(devServiceConnection)'
        backendAzureRmResourceGroupName: 'rg-terraform-state'
        backendAzureRmStorageAccountName: '$(TF_STATE_STORAGE_ACCOUNT)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'dev.terraform.tfstate'
    
    - task: TerraformTaskV4@4
      displayName: 'Terraform Plan'
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(System.DefaultWorkingDirectory)/infrastructure/terraform/environments/dev'
        environmentServiceNameAzureRM: '$(devServiceConnection)'
    
    - task: TerraformTaskV4@4
      displayName: 'Terraform Apply'
      inputs:
        provider: 'azurerm'
        command: 'apply'
        workingDirectory: '$(System.DefaultWorkingDirectory)/infrastructure/terraform/environments/dev'
        environmentServiceNameAzureRM: '$(devServiceConnection)'
```

---

## 8. CI/CD Pipeline Setup

### 8.1 Main Pipeline Configuration

Update `cicd/azure-pipelines.yml` with self-hosted agent configuration:

```yaml
trigger:
  branches:
    include:
      - dev
      - int
      - release/*

variables:
  - name: buildConfiguration
    value: 'Release'
  - name: artifactName
    value: 'databricks-enterprise-platform'

pool:
  vmImage: 'ubuntu-latest'  # For change detection and validation

stages:

# ============================================================================
# STAGE 1: CHANGE DETECTION (Runs on Azure-hosted agent)
# ============================================================================
- stage: ChangeDetection
  displayName: 'Detect Changed Components'
  pool:
    vmImage: 'ubuntu-latest'
  jobs:
  - job: DetectChanges
    displayName: 'Detect Changes'
    steps:
    - checkout: self
      fetchDepth: 0
    
    - script: |
        bash cicd/scripts/detect-changes.sh
      displayName: 'Detect Changed Files'
      name: detectChanges

# ============================================================================
# STAGE 2: CI VALIDATION (Runs on Azure-hosted agent)
# ============================================================================
- stage: CI_Validation
  displayName: 'CI Validation'
  dependsOn: ChangeDetection
  pool:
    vmImage: 'ubuntu-latest'
  variables:
    TERRAFORM_CHANGED: $[ stageDependencies.ChangeDetection.DetectChanges.outputs['detectChanges.TERRAFORM_CHANGED'] ]
    ADF_CHANGED: $[ stageDependencies.ChangeDetection.DetectChanges.outputs['detectChanges.ADF_CHANGED'] ]
    DATABRICKS_CHANGED: $[ stageDependencies.ChangeDetection.DetectChanges.outputs['detectChanges.DATABRICKS_CHANGED'] ]
  jobs:
  - template: templates/stages/ci-validation.yml
    parameters:
      terraformChanged: $(TERRAFORM_CHANGED)
      adfChanged: $(ADF_CHANGED)
      databricksChanged: $(DATABRICKS_CHANGED)

# ============================================================================
# STAGE 3: BUILD (Runs on Azure-hosted agent)
# ============================================================================
- stage: Build
  displayName: 'Build Artifacts'
  dependsOn: CI_Validation
  pool:
    vmImage: 'ubuntu-latest'
  jobs:
  - template: templates/stages/build-artifacts.yml

# ============================================================================
# STAGE 4: DEV DEPLOYMENT (Runs on Self-Hosted agent)
# ============================================================================
- stage: Deploy_DEV
  displayName: 'Deploy to DEV'
  dependsOn: Build
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/dev')
  variables:
    - group: vg-dev-config
    - group: vg-shared-config
  jobs:
  - template: templates/stages/deploy-dev.yml
    parameters:
      environment: 'DEV'
      agentPool: $(AGENT_POOL)  # From variable group
      serviceConnection: $(devServiceConnection)
      resourceGroup: $(devResourceGroup)

# ============================================================================
# STAGE 5: INT DEPLOYMENT (Runs on Self-Hosted agent)
# ============================================================================
- stage: Deploy_INT
  displayName: 'Deploy to INT'
  dependsOn: Deploy_DEV
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/int')
  variables:
    - group: vg-int-config
    - group: vg-shared-config
  jobs:
  - template: templates/stages/deploy-int.yml
    parameters:
      environment: 'INT'
      agentPool: $(AGENT_POOL)
      serviceConnection: $(intServiceConnection)
      resourceGroup: $(intResourceGroup)

# ============================================================================
# STAGE 6: PRD DEPLOYMENT (Runs on Self-Hosted agent, Manual Approval)
# ============================================================================
- stage: Deploy_PRD
  displayName: 'Deploy to PRODUCTION'
  dependsOn: Deploy_INT
  condition: startsWith(variables['Build.SourceBranch'], 'refs/heads/release/')
  variables:
    - group: vg-prd-config
    - group: vg-shared-config
  jobs:
  - template: templates/stages/deploy-prd.yml
    parameters:
      environment: 'PRD'
      agentPool: $(AGENT_POOL)
      serviceConnection: $(prdServiceConnection)
      resourceGroup: $(prdResourceGroup)
      requireApproval: true
```

### 8.2 Deployment Template with Self-Hosted Agent

Update deployment templates to use self-hosted agents:

```yaml
# In deploy-dev.yml, deploy-int.yml, deploy-prd.yml

parameters:
  - name: agentPool
    type: string
  - name: environment
    type: string
  - name: serviceConnection
    type: string

jobs:
- job: Deploy
  displayName: 'Deploy to ${{ parameters.environment }}'
  pool:
    name: ${{ parameters.agentPool }}  # Self-hosted agent pool
  steps:
    - checkout: self
    
    - task: AzureCLI@2
      displayName: 'Azure Login with Federated Identity'
      inputs:
        azureSubscription: '${{ parameters.serviceConnection }}'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          echo "Logged in to Azure using Federated Identity"
          az account show
    
    # Rest of deployment steps...
```

### 8.3 Configure Pipeline

1. Go to Pipelines → New Pipeline
2. Select "Azure Repos Git"
3. Select your repository
4. Select "Existing Azure Pipelines YAML file"
5. Path: `/cicd/azure-pipelines.yml`
6. Click "Run"

---

## 9. Testing & Validation

### 9.1 Pre-Deployment Checklist

```bash
# Run validation script
pwsh cicd/config/validate-variable-groups.ps1 \
    -OrganizationUrl "https://dev.azure.com/YOUR_ORG" \
    -ProjectName "YOUR_PROJECT" \
    -ExportReport \
    -ReportPath "./validation-report.txt"
```

**Verify**:
- ✅ All variable groups exist
- ✅ No placeholder values remaining
- ✅ Service connections configured
- ✅ Self-hosted agents online
- ✅ Terraform backend accessible

### 9.2 Test Deployment Flow

#### Test 1: Terraform-Only Change

```bash
# Make a small Terraform change
cd infrastructure/terraform/environments/dev
echo "# Test change" >> main.tf

git add .
git commit -m "test: Terraform change detection"
git push origin dev
```

**Expected**:
- Pipeline triggers
- Change detection identifies Terraform change
- Only Terraform deployment runs
- ADF and Databricks deployments skipped

#### Test 2: Multi-Component Change

```bash
# Change multiple components
touch databricks/notebooks/test.py
touch adf/pipeline/test-pipeline.json

git add .
git commit -m "test: Multi-component change"
git push origin dev
```

**Expected**:
- Multiple component deployments run in parallel
- Each uses correct self-hosted agent
- All deployments succeed

### 9.3 Validation Tests

**Create test script** `cicd/scripts/validate-deployment.sh`:

```bash
#!/bin/bash

set -e

ENVIRONMENT=$1

echo "Validating $ENVIRONMENT deployment..."

# Test Databricks connectivity
echo "Testing Databricks..."
az databricks workspace show \
    --resource-group "rg-databricks-${ENVIRONMENT}" \
    --name "dbw-dataeng-${ENVIRONMENT}" \
    --query "workspaceUrl" -o tsv

# Test ADF connectivity
echo "Testing Azure Data Factory..."
az datafactory show \
    --resource-group "rg-databricks-${ENVIRONMENT}" \
    --name "adf-dataeng-${ENVIRONMENT}" \
    --query "provisioningState" -o tsv

# Test Storage Account
echo "Testing Storage Account..."
az storage account show \
    --resource-group "rg-databricks-${ENVIRONMENT}" \
    --name "stdataeng${ENVIRONMENT}" \
    --query "provisioningState" -o tsv

echo "✅ All validations passed for $ENVIRONMENT!"
```

---

## 10. Monitoring & Troubleshooting

### 10.1 Pipeline Monitoring

**Azure DevOps Dashboards**:

1. Create custom dashboard:
   - Overview → Dashboards → New Dashboard
   - Add widgets:
     - Pipeline success rate
     - Average pipeline duration
     - Failed pipelines
     - Agent availability

### 10.2 Common Issues & Solutions

#### Issue 1: "Failed to get federated token"

**Cause**: Federated credential not properly configured

**Solution**:
```bash
# Verify federated credential
az ad app federated-credential list --id $APP_ID

# Check subject matches service connection
az devops service-endpoint show --id $SC_ID

# Update if needed
az ad app federated-credential update ...
```

#### Issue 2: "Self-hosted agent offline"

**Cause**: Agent service stopped or VM shut down

**Solution**:
```bash
# SSH to VM
ssh azureuser@VM_IP

# Check agent status
sudo ./svc.sh status

# Restart if needed
sudo ./svc.sh restart

# Check logs
tail -f _diag/*.log
```

#### Issue 3: "Terraform state lock"

**Cause**: Previous run didn't release lock

**Solution**:
```bash
# List locks
az storage blob lease list \
    --account-name "sttfstate" \
    --container-name "tfstate"

# Break lease if needed (CAUTION!)
az storage blob lease break \
    --account-name "sttfstate" \
    --container-name "tfstate" \
    --blob-name "dev.terraform.tfstate"
```

### 10.3 Logging & Diagnostics

**Enable Azure DevOps diagnostic logging**:

```yaml
# Add to pipeline
variables:
  - name: System.Debug
    value: true
```

**View Terraform logs**:
```bash
# On self-hosted agent
cd /home/azureuser/azdo-agent/_work/1/s/infrastructure/terraform/environments/dev
cat terraform.log
```

---

## 11. Security Best Practices

### 11.1 Secret Management

✅ **DO**:
- Store secrets in Azure Key Vault
- Link Key Vault to Variable Groups
- Use managed identities where possible
- Rotate credentials regularly
- Use federated identity (no secrets in pipeline)

❌ **DON'T**:
- Store secrets in variable groups as plain text
- Commit secrets to Git
- Use long-lived PATs
- Share credentials between environments

### 11.2 RBAC Configuration

**Principle of Least Privilege**:

```bash
# DEV Service Principal: Contributor on DEV resources only
az role assignment create \
    --assignee $DEV_SP_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUB_ID/resourceGroups/rg-databricks-dev"

# PRD Service Principal: Separate, restricted permissions
az role assignment create \
    --assignee $PRD_SP_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUB_ID/resourceGroups/rg-databricks-prd" \
    --condition "..."
```

### 11.3 Network Security

**Secure self-hosted agents**:

```bash
# Create NSG rule to restrict SSH access
az network nsg rule create \
    --resource-group "rg-databricks-dev" \
    --nsg-name "nsg-agent-dev" \
    --name "AllowSSHFromCorporate" \
    --priority 100 \
    --source-address-prefixes "YOUR_CORPORATE_IP" \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp

# Deny all other SSH
az network nsg rule create \
    --resource-group "rg-databricks-dev" \
    --nsg-name "nsg-agent-dev" \
    --name "DenyAllSSH" \
    --priority 200 \
    --destination-port-ranges 22 \
    --access Deny \
    --protocol Tcp
```

### 11.4 Audit Logging

**Enable Azure activity logs**:

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
    --resource-group "rg-monitoring" \
    --workspace-name "law-databricks-audit" \
    --location "eastus"

# Enable diagnostic settings
az monitor diagnostic-settings create \
    --name "audit-logs" \
    --resource "/subscriptions/$SUB_ID" \
    --workspace "law-databricks-audit" \
    --logs '[{"category": "Administrative", "enabled": true}]'
```

---

## 12. Appendix

### 12.1 Useful Commands Reference

```bash
# Azure CLI
az account show                          # Current subscription
az ad sp list --display-name "sp-name"   # List service principals
az role assignment list --assignee $ID   # List role assignments

# Azure DevOps CLI
az devops project list                   # List projects
az pipelines run --name "pipeline-name"  # Trigger pipeline
az pipelines variable-group list         # List variable groups

# Terraform
terraform init                           # Initialize
terraform plan -out=tfplan              # Plan
terraform apply tfplan                   # Apply
terraform destroy                        # Destroy

# Databricks CLI
databricks workspace list                # List workspaces
databricks jobs list                     # List jobs
```

### 12.2 Variable Groups Quick Reference

| Variable Group | Purpose | Key Variables |
|----------------|---------|---------------|
| vg-shared-config | Common settings | AZURE_SUBSCRIPTION_ID, AZURE_LOCATION, TF_STATE_STORAGE_ACCOUNT |
| vg-dev-config | DEV environment | devServiceConnection, DEV_DATABRICKS_HOST, AGENT_POOL |
| vg-int-config | INT environment | intServiceConnection, INT_DATABRICKS_HOST, AGENT_POOL |
| vg-prd-config | PRD environment | prdServiceConnection, PRD_DATABRICKS_HOST, AGENT_POOL |

### 12.3 Deployment Checklist

**Before First Deployment**:
- [ ] Service principals created with federated identity
- [ ] RBAC roles assigned
- [ ] Self-hosted agents installed and online
- [ ] Variable groups created and populated
- [ ] Service connections configured
- [ ] Terraform backend accessible
- [ ] Branch policies configured
- [ ] Approval gates set up for PRD

**Before Each Deployment**:
- [ ] Pull latest code
- [ ] Review changes
- [ ] Run local validation
- [ ] Verify agent availability
- [ ] Check Terraform plan
- [ ] Notify stakeholders

### 12.4 Troubleshooting Decision Tree

```
Pipeline Failed?
    │
    ├─ Authentication Error?
    │   ├─ Check service connection
    │   ├─ Verify federated credential
    │   └─ Check SP permissions
    │
    ├─ Agent Not Available?
    │   ├─ Check agent status on VM
    │   ├─ Verify agent pool configuration
    │   └─ Check VM running state
    │
    ├─ Terraform Error?
    │   ├─ Check state lock
    │   ├─ Verify backend configuration
    │   └─ Review Terraform logs
    │
    └─ Resource Deployment Error?
        ├─ Check RBAC permissions
        ├─ Verify resource quotas
        └─ Review Azure activity logs
```

### 12.5 Support Resources

**Documentation**:
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Databricks Documentation](https://docs.microsoft.com/en-us/azure/databricks/)
- [Workload Identity Federation](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)

**Community**:
- Azure DevOps Community: https://developercommunity.visualstudio.com/
- Terraform Community: https://discuss.hashicorp.com/

---

## Summary

You now have a complete enterprise CI/CD setup with:

✅ **Security**: Federated identity (no secrets)  
✅ **Scalability**: Self-hosted agents  
✅ **Flexibility**: Dynamic configuration via variable groups  
✅ **Efficiency**: Change-based deployment  
✅ **Reliability**: Infrastructure as code with Terraform  
✅ **Compliance**: Full audit trail and approval gates  

**Next Steps**:
1. Review and customize configurations for your organization
2. Test in DEV environment first
3. Gradually roll out to INT and PRD
4. Monitor and iterate based on feedback

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-XX  
**Maintained By**: DevOps Team  
**Status**: Production Ready