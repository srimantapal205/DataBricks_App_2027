# Azure DevOps CI/CD Pipeline Architecture
## Enterprise-Grade Data Engineering Solution

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Pipeline Flow](#pipeline-flow)
4. [Repository Structure](#repository-structure)
5. [Change-Based Deployment](#change-based-deployment)
6. [Environment Strategy](#environment-strategy)
7. [Security & Credentials](#security--credentials)
8. [Approval Gates](#approval-gates)
9. [Rollback Strategy](#rollback-strategy)
10. [Configuration Guide](#configuration-guide)
11. [Best Practices](#best-practices)

---

## Overview

This CI/CD pipeline implements an enterprise-grade deployment solution for Azure data engineering workloads across three environments:

**Feature → DEV → INT → PRD**

### Key Features
- ✓ Build Once, Deploy Many
- ✓ Change-File-Based Deployment
- ✓ Automated Validation & Testing
- ✓ Environment-Specific Configuration
- ✓ Production Approval Gates
- ✓ Complete Audit Trail
- ✓ Rollback Capability
- ✓ Low Merge Conflicts

---

## Architecture Principles

### 1. Build Once, Deploy Many
Artifacts are built once during CI and promoted through all environments:

```
Source Code
    ↓
CI Validation
    ↓
Build Artifacts (Immutable)
    ↓
  DEV
    ↓
  INT
    ↓
  PRD
```

* **Same artifact** is deployed to all environments
* **Environment-specific configuration** is injected at deployment time
* **No rebuilds** between environments
* **Artifact integrity** is verified at each stage

### 2. Change-Based Deployment
Only changed components are validated and deployed:

```
Change Detection
    ↓
Identify Changed Components
    ↓
Validate Only Changed Components
    ↓
Deploy Only Changed Components
```

**Benefits:**
* Faster CI/CD execution
* Reduced risk (only changed components are touched)
* Clearer deployment audit trail
* Optimized resource utilization

### 3. Fail-Fast Validation
Multiple validation layers:

```
Level 1: Branch Policy Validation (PR)
Level 2: Syntax & Format Validation
Level 3: Security Scanning
Level 4: Unit Tests
Level 5: Build Artifact Creation
Level 6: DEV Deployment & Smoke Tests
Level 7: INT Deployment & Integration Tests
Level 8: Production Approval
Level 9: PRD Deployment & Health Checks
```

---

## Pipeline Flow

### Stage 1: Change Detection
**Purpose:** Identify which components have changed

**Process:**
1. Compare source branch with target branch
2. Analyze changed files by path pattern
3. Set output variables for downstream stages

**Output Variables:**
* `ADF_CHANGED` - true/false
* `DATABRICKS_CHANGED` - true/false
* `SQL_CHANGED` - true/false
* `TERRAFORM_CHANGED` - true/false
* `TESTS_CHANGED` - true/false

### Stage 2: CI Validation
**Purpose:** Comprehensive validation of all code

**Jobs:**
1. **Code Quality & Security**
   * Python linting (pylint, flake8)
   * Security scanning (bandit)
   * Secret detection
   * Dependency scanning

2. **ADF Validation** (conditional)
   * JSON schema validation
   * Naming convention checks
   * Dependency analysis

3. **Databricks Validation** (conditional)
   * Notebook syntax validation
   * PySpark code checks
   * Workflow configuration validation

4. **SQL Validation** (conditional)
   * SQL syntax checking (sqlfluff)
   * Naming conventions

5. **Terraform Validation** (conditional)
   * `terraform fmt` check
   * `terraform validate`
   * Security scanning (checkov)

6. **Unit Tests** (conditional)
   * Execute unit tests
   * Publish test results
   * Publish code coverage

### Stage 3: Build Artifacts
**Purpose:** Create immutable deployment artifacts

**Process:**
1. Create build manifest with metadata
2. Package ADF artifacts
3. Package Databricks artifacts (notebooks, workflows, wheels)
4. Package SQL scripts
5. Package Terraform configurations
6. Package deployment scripts
7. Calculate checksums
8. Create version file
9. Publish pipeline artifact

**Artifact Structure:**
```
data-engineering-solution/
├── build-manifest.json
├── version.txt
├── checksums.txt
├── adf/
├── databricks/
├── sql/
├── terraform/
├── config/
└── scripts/
```

### Stage 4: DEV Deployment
**Purpose:** Automated deployment to DEV environment

**Jobs:**
1. **Pre-Deployment Validation**
   * Download artifacts
   * Verify checksums
   * Display version info

2. **Deploy Terraform** (conditional)
   * Init, plan, apply

3. **Deploy ADF** (conditional)
   * Stop triggers
   * Deploy ARM template
   * Start triggers

4. **Deploy Databricks** (conditional)
   * Deploy notebooks
   * Deploy workflows

5. **Deploy SQL** (conditional)
   * Execute migration scripts

6. **Smoke Tests**
   * Connectivity tests
   * Basic functionality tests

### Stage 5: INT Deployment
**Purpose:** Deployment to INT with integration testing

**Jobs:**
1. **Deploy to INT** (Azure DevOps Environment)
   * Same artifact as DEV
   * INT-specific configuration

2. **Integration Tests**
   * ADF pipeline execution tests
   * Databricks job execution tests
   * End-to-end data flow tests

3. **Data Validation**
   * Data completeness checks
   * Data accuracy validation
   * Data freshness checks

4. **Performance Tests**
   * Pipeline execution time
   * Query performance

### Stage 6: PRD Deployment
**Purpose:** Production deployment with approval gates

**Jobs:**
1. **Pre-Production Validation**
   * Artifact integrity check
   * Display deployment plan
   * Deployment checklist

2. **Deploy to PRD** (Azure DevOps Environment with approval)
   * Manual approval required
   * Create pre-deployment backup
   * Deploy all components
   * Post-deployment health check

3. **Production Smoke Tests**
   * Critical path testing
   * User connectivity testing
   * Data integrity checks

4. **Deployment Audit Log**
   * Create audit record
   * Store in audit system

---

## Repository Structure

```
repo/
├── azure-pipelines.yml              # Main pipeline orchestration
├── README.md
├── .gitignore
├── templates/                       # YAML templates
│   ├── stages/
│   │   ├── ci-validation.yml
│   │   ├── build-artifacts.yml
│   │   ├── deploy-dev.yml
│   │   ├── deploy-int.yml
│   │   └── deploy-prd.yml
│   ├── jobs/
│   │   └── change-detection.yml
│   └── steps/
├── infrastructure/
│   └── terraform/
│       ├── modules/
│       └── environments/
│           ├── dev/
│           ├── int/
│           └── prd/
├── adf/
│   ├── pipelines/
│   ├── datasets/
│   ├── linkedServices/
│   └── triggers/
├── databricks/
│   ├── notebooks/
│   ├── workflows/
│   ├── resources/
│   └── src/
├── sql/
│   ├── tables/
│   ├── views/
│   └── procedures/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── validation/
├── config/
│   ├── dev/
│   ├── int/
│   └── prd/
└── scripts/
    ├── detect-changes.ps1
    ├── validate.ps1
    └── deploy.ps1
```

---

## Change-Based Deployment

### How It Works

1. **Change Detection Script** (`scripts/detect-changes.ps1`)
   * Compares files between source and target branches
   * Uses path patterns to identify component changes
   * Sets Azure DevOps output variables

2. **Pattern Matching**
```powershell
adf/**              → ADF_CHANGED=true
databricks/**       → DATABRICKS_CHANGED=true
sql/**              → SQL_CHANGED=true
infrastructure/**   → TERRAFORM_CHANGED=true
tests/**            → TESTS_CHANGED=true
```

3. **Conditional Execution**
```yaml
- job: DeployADF
  condition: eq(variables['ADF_CHANGED'], 'true')
  steps:
    # Deploy ADF
```

### Benefits
* **Faster Deployments**: Only changed components are processed
* **Reduced Risk**: Unchanged components are not touched
* **Clear Audit Trail**: Deployment logs show exactly what changed
* **Resource Efficiency**: No unnecessary deployments

---

## Environment Strategy

### Environment Progression

```
DEV (Development)
  ↓ Automatic after successful CI
INT (Integration)
  ↓ Automatic after successful DEV
PRD (Production)
  ↓ Manual approval required
```

### Azure DevOps Environments

Create these environments in Azure DevOps:

#### 1. DEV Environment
* **Purpose**: Development testing
* **Approvals**: None (automatic)
* **Service Connection**: `dev-service-connection`
* **Branch Triggers**: `dev`, `feature/*`

#### 2. INT Environment
* **Purpose**: Integration testing
* **Approvals**: Optional (auto-approve or require 1 reviewer)
* **Service Connection**: `int-service-connection`
* **Branch Triggers**: `int`, `dev`

#### 3. PRD Environment
* **Purpose**: Production
* **Approvals**: **REQUIRED** (minimum 2 authorized approvers)
* **Service Connection**: `prd-service-connection`
* **Branch Triggers**: `release/prd`, `release/*`
* **Business Hours Gate**: Optional

### Environment Configuration

**Variable Groups** (Azure DevOps Library):

1. **vg-shared-config** (shared across all environments)
   * `AZURE_SUBSCRIPTION_ID`
   * `AZURE_LOCATION`
   * `TF_STATE_STORAGE_ACCOUNT`

2. **vg-dev-config**
   * `devServiceConnection`
   * `devResourceGroup`
   * `DEV_ADF_NAME`
   * `DEV_DATABRICKS_HOST`
   * Other DEV-specific variables

3. **vg-int-config**
   * `intServiceConnection`
   * `intResourceGroup`
   * `INT_ADF_NAME`
   * `INT_DATABRICKS_HOST`
   * Other INT-specific variables

4. **vg-prd-config**
   * `prdServiceConnection`
   * `prdResourceGroup`
   * `PRD_ADF_NAME`
   * `PRD_DATABRICKS_HOST`
   * Other PRD-specific variables

---

## Security & Credentials

### Principle: Zero Secrets in Git

**NEVER store in Git:**
* ✗ Passwords
* ✗ Connection strings with credentials
* ✗ Access keys
* ✗ Tokens
* ✗ Certificates/private keys
* ✗ API keys

### Security Architecture

1. **Azure Key Vault**
   * Store all secrets
   * Reference from variable groups
   * Use Managed Identity where possible

2. **Azure DevOps Service Connections**
   * One per environment
   * Use Workload Identity Federation (preferred)
   * Or Managed Identity
   * Least-privilege RBAC

3. **Azure DevOps Variable Groups**
   * Link to Key Vault
   * Mark secrets as "secret"
   * Environment-specific groups

4. **Terraform State**
   * Store in Azure Storage with encryption
   * Use separate state files per environment
   * Enable versioning and soft delete

### Security Scanning

Pipeline includes:
* **Secret Detection**: Scan code for accidentally committed secrets
* **Dependency Scanning**: Check for vulnerable dependencies (safety, npm audit)
* **Security Linting**: Bandit for Python, checkov for Terraform
* **Infrastructure Security**: Terraform security scans

---

## Approval Gates

### Pull Request Validation

**Feature → Dev:**
* Minimum 1 reviewer
* Build validation must pass
* Work item linking (optional)
* Comment resolution

**Dev → INT:**
* Minimum 1 reviewer
* All CI validations must pass
* No work items required

**INT → PRD:**
* **Minimum 2 authorized reviewers**
* **Production change board approval** (if applicable)
* All INT tests must pass
* Security validation complete

### Environment Approvals

**PRD Environment in Azure DevOps:**
* **Pre-Deployment Approval**: Required before deployment starts
* **Approvers**: Designated production approvers
* **Timeout**: 30 days
* **Business Hours Gate**: Optional (only deploy during business hours)
* **Post-Deployment Approval**: Optional

---

## Rollback Strategy

### Application Rollback

**Method 1: Rerun Previous Build**
* Navigate to previous successful build
* Rerun deployment stages
* Artifact is immutable and still available

**Method 2: Revert and Redeploy**
* Revert commit in Git
* Push to trigger new build
* New artifact created from reverted code

### Infrastructure Rollback

**Terraform:**
* Revert to previous Terraform code
* Run `terraform plan` and `terraform apply`
* State file maintains history

### Database Rollback

**Strategy: Forward-Fix Preferred**
* Use backward-compatible migrations
* Add columns rather than modify
* Create new tables/views alongside old ones
* Switch over after validation
* Rollback = switch back to old tables/views

**Emergency Rollback:**
* Restore database backup
* **ONLY** in catastrophic scenarios
* Requires downtime

### ADF Rollback
* Previous ADF ARM template is in artifact history
* Redeploy previous artifact
* Triggers are stopped during deployment

### Databricks Rollback
* Previous notebooks/workflows are in artifact history
* Redeploy previous artifact
* Databricks workspace maintains version history

---

## Configuration Guide

### 1. Azure DevOps Setup

#### Create Service Connections
```
Project Settings → Service Connections → New Service Connection → Azure Resource Manager

Create:
* dev-service-connection (DEV subscription)
* int-service-connection (INT subscription)
* prd-service-connection (PRD subscription)

Authentication: Workload Identity Federation (recommended)
```

#### Create Variable Groups
```
Pipelines → Library → Variable Groups → + Variable Group

Create:
* vg-shared-config
* vg-dev-config
* vg-int-config
* vg-prd-config

Link to Azure Key Vault where applicable
```

#### Create Environments
```
Pipelines → Environments → New Environment

Create:
* DEV
  - No approvals
  
* INT
  - Optional: Add approvals
  
* PRD
  - Approvals: Required (minimum 2 approvers)
  - Add authorized production approvers
```

#### Configure Branch Policies
```
Repos → Branches → Select branch → Branch policies

For 'dev' branch:
* Require a minimum of 1 reviewer
* Check for linked work items: Optional
* Check for comment resolution: Required
* Build validation: Add azure-pipelines.yml

For 'int' branch:
* Same as dev
* Require a minimum of 1 reviewer

For 'release/prd' branch:
* Require a minimum of 2 reviewers
* Reviewers must be from authorized list
* Build validation required
* All policies strict
```

### 2. Repository Configuration

#### Branch Structure
```
main
  ├── dev
  │   └── feature/feature-name
  ├── int
  └── release/prd
```

#### Git Workflow
1. Create feature branch from `dev`
2. Develop and commit changes
3. Create PR: `feature/feature-name` → `dev`
4. After approval and CI pass, merge to `dev`
5. Auto-deploy to DEV
6. Create PR: `dev` → `int`
7. After approval, merge to `int`
8. Auto-deploy to INT
9. Create PR: `int` → `release/prd`
10. After approval, merge to `release/prd`
11. Manual approval required for PRD deployment

---

## Best Practices

### 1. Minimize Merge Conflicts
* Keep feature branches short-lived (< 1 week)
* Frequently sync feature branches with dev
* Small, focused commits
* Separate environment config from code
* Use reusable YAML templates
* Avoid modifying generated files

### 2. Security
* Never commit secrets
* Use Key Vault for all credentials
* Scan for secrets in CI
* Use Managed Identity where possible
* Separate service connections per environment
* Least-privilege RBAC

### 3. Testing
* Write unit tests for all business logic
* Include integration tests
* Test on realistic data subsets
* Validate data quality
* Monitor test coverage

### 4. Deployment
* Deploy frequently to catch issues early
* Deploy during low-traffic windows for PRD
* Monitor deployments closely
* Have rollback plan ready
* Communicate deployments to stakeholders

### 5. Documentation
* Document deployment process
* Maintain runbooks
* Document rollback procedures
* Keep architecture diagrams updated
* Document breaking changes

### 6. Monitoring & Observability
* Log all deployments
* Monitor pipeline execution
* Track deployment frequency
* Monitor failure rates
* Set up alerts for failures

---

## Quick Start

### 1. Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd <repository>

# Create environment-specific configuration
cp config/dev/sample.json config/dev/actual.json
cp config/int/sample.json config/int/actual.json
cp config/prd/sample.json config/prd/actual.json

# Update with your environment values (NOT secrets)
```

### 2. Local Validation
```powershell
# Run validation locally
.\scripts\validate.ps1 -Component all

# Run change detection
.\scripts\detect-changes.ps1 -SourceBranch feature/my-feature -TargetBranch dev
```

### 3. Create Feature Branch
```bash
git checkout dev
git pull
git checkout -b feature/my-feature

# Make changes
git add .
git commit -m "feat: add new data pipeline"
git push origin feature/my-feature
```

### 4. Create Pull Request
* Navigate to Azure DevOps Repos
* Create PR: `feature/my-feature` → `dev`
* Add reviewers
* Link work items
* Wait for build validation

### 5. Monitor Deployment
* After PR merge, pipeline triggers automatically
* Monitor in Azure DevOps Pipelines
* Check each stage: CI → Build → DEV → INT → PRD
* For PRD, manual approval required

---

## Troubleshooting

### Pipeline Fails at Change Detection
**Cause**: Git history not available
**Solution**: Ensure `fetchDepth: 0` in checkout step

### Terraform Validation Fails
**Cause**: Backend configuration missing
**Solution**: Use `-backend=false` for validation-only init

### ADF Deployment Fails
**Cause**: Triggers still running
**Solution**: Ensure triggers are stopped before deployment

### Artifact Checksum Mismatch
**Cause**: Artifact corruption or tampering
**Solution**: Re-run build to create new artifact

### Production Approval Timeout
**Cause**: No approvers available
**Solution**: Add multiple approvers, extend timeout

---

## Support & Contact

For questions or issues:
* Technical questions: [Team Email]
* Production deployments: [Production Team]
* Emergency rollback: [On-Call Engineer]

---

**Version**: 1.0  
**Last Updated**: 2024  
**Status**: Production Ready