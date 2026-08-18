# Azure DevOps CI/CD Pipeline
## Enterprise-Grade Data Engineering Solution

[![Build Status](https://dev.azure.com/your-org/your-project/_apis/build/status/data-engineering-pipeline)](https://dev.azure.com/your-org/your-project/_build/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## ✨ Overview

This repository contains a production-grade CI/CD pipeline for deploying Azure data engineering solutions across **DEV → INT → PRD** environments.

### Key Features

✓ **Build Once, Deploy Many** - Immutable artifacts promoted through all environments  
✓ **Change-Based Deployment** - Only changed components are validated and deployed  
✓ **Automated Validation** - Comprehensive CI with 10+ validation gates  
✓ **Security First** - Secret scanning, dependency checks, security linting  
✓ **Production Gates** - Manual approval required for production deployments  
✓ **Complete Audit Trail** - Full deployment history for compliance  
✓ **Rollback Ready** - Built-in rollback capabilities  
✓ **Low Merge Conflicts** - Optimized Git branching strategy  

---

## 📚 Documentation

* **[Architecture Guide](docs/ARCHITECTURE.md)** - Complete architecture documentation
* **[Setup Guide](docs/SETUP_GUIDE.md)** - Step-by-step setup instructions
* **[Branching Strategy](docs/BRANCHING_STRATEGY.md)** - Git workflow and branch policies
* **[Rollback Guide](docs/ROLLBACK_GUIDE.md)** - Rollback procedures
* **[Best Practices](docs/BEST_PRACTICES_CHECKLIST.md)** - Development best practices

---

## 🚀 Quick Start

### Prerequisites

* Azure DevOps organization and project
* Azure subscription (DEV, INT, PRD)
* Terraform installed locally (for validation)
* Python 3.10+ (for local testing)
* PowerShell 7+ (for scripts)

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd <repository>

# Install Python dependencies (for local testing)
pip install -r requirements.txt

# Install pre-commit hooks (optional)
pre-commit install
```

### 2. Configure Azure DevOps

Follow the **[Setup Guide](docs/SETUP_GUIDE.md)** to configure:

1. Service connections (DEV, INT, PRD)
2. Variable groups
3. Environments with approval gates
4. Branch policies

### 3. Create Feature Branch

```bash
# Start from dev branch
git checkout dev
git pull origin dev

# Create feature branch
git checkout -b feature/my-feature

# Make changes...

# Validate locally
.\scripts\validate.ps1 -Component all

# Commit and push
git add .
git commit -m "feat: add new data pipeline"
git push origin feature/my-feature
```

### 4. Create Pull Request

1. Navigate to Azure DevOps Repos
2. Create PR: `feature/my-feature` → `dev`
3. Add reviewers
4. Wait for CI validation to pass
5. Merge after approval

### 5. Monitor Deployment

After merging to `dev`, the pipeline automatically:

1. ✓ Detects changed components
2. ✓ Validates all code
3. ✓ Builds immutable artifacts
4. ✓ Deploys to DEV
5. ✓ Runs smoke tests
6. ✓ Deploys to INT (if merged to `int`)
7. ✓ Runs integration tests
8. ✓ Awaits manual approval for PRD
9. ✓ Deploys to PRD
10. ✓ Runs production health checks

---

## 🏛️ Architecture

### Pipeline Flow

```
┌───────────────────┐
│ Change Detection  │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│    CI Validation     │
│  ▪ Python Linting    │
│  ▪ Security Scan     │
│  ▪ Terraform Valid   │
│  ▪ Unit Tests        │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│  Build Artifacts   │
│  (Immutable)       │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│   Deploy to DEV    │
│  ▪ Terraform        │
│  ▪ ADF              │
│  ▪ Databricks       │
│  ▪ SQL              │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│   Deploy to INT    │
│  ▪ Integration Tests│
│  ▪ Data Validation  │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│ [APPROVAL GATE]   │
└──────────┬─────────┘
           │
┌──────────┴─────────┐
│   Deploy to PRD    │
│  ▪ Backup Created  │
│  ▪ Components       │
│  ▪ Health Check     │
└───────────────────┘
```

### Change-Based Deployment

The pipeline intelligently detects which components have changed:

| Path Pattern | Component | Action |
|--------------|-----------|--------|
| `adf/**` | Azure Data Factory | Validate & Deploy ADF |
| `databricks/**` | Databricks | Validate & Deploy Notebooks/Workflows |
| `sql/**` | SQL Scripts | Validate & Deploy SQL |
| `infrastructure/**` | Terraform | Validate & Deploy Infrastructure |
| `tests/**` | Tests | Run Tests |
| `docs/**` | Documentation | Skip Deployment |

---

## 💻 Development Workflow

### Branch Strategy

```
main
 ├── dev                    (Development)
 │   └── feature/*         (Feature branches)
 ├── int                    (Integration)
 └── release/prd            (Production)
```

### Feature Development

1. **Create Feature Branch**
   ```bash
   git checkout dev
   git checkout -b feature/my-feature
   ```

2. **Develop & Test Locally**
   ```bash
   # Validate code
   .\scripts\validate.ps1 -Component all
   
   # Run unit tests
   pytest tests/unit/
   ```

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

4. **Create Pull Request**
   * PR: `feature/my-feature` → `dev`
   * Add reviewers
   * Wait for CI validation

5. **Merge & Deploy**
   * After approval, merge PR
   * Automatic deployment to DEV

### Environment Promotion

**DEV → INT**
```bash
git checkout int
git merge dev
git push origin int
# Triggers deployment to INT
```

**INT → PRD**
```bash
git checkout release/prd
git merge int
git push origin release/prd
# Triggers approval workflow for PRD
```

---

## 🛠️ Repository Structure

```
├── azure-pipelines.yml          # Main pipeline
├── templates/
│   ├── stages/                   # Stage templates
│   ├── jobs/                     # Job templates
│   └── steps/                    # Step templates
├── scripts/
│   ├── detect-changes.ps1        # Change detection
│   └── validate.ps1              # Local validation
├── config/
│   ├── dev/                      # DEV configuration
│   ├── int/                      # INT configuration
│   └── prd/                      # PRD configuration
├── infrastructure/
│   └── terraform/                # Terraform IaC
├── adf/                          # Azure Data Factory
├── databricks/                   # Databricks assets
├── sql/                          # SQL scripts
├── tests/                        # Unit & integration tests
└── docs/                         # Documentation
```

---

## 🔒 Security

### Zero Secrets in Git

**NEVER commit:**
* Passwords
* Connection strings with credentials
* Access keys or tokens
* Certificates or private keys

### Security Measures

* ✓ Azure Key Vault for all secrets
* ✓ Workload Identity Federation
* ✓ Managed Identity where possible
* ✓ Secret scanning in CI
* ✓ Dependency vulnerability scanning
* ✓ Terraform security scanning
* ✓ Least-privilege RBAC

---

## 📊 Monitoring & Observability

### Pipeline Metrics

* Build success rate
* Deployment frequency
* Lead time for changes
* Mean time to recovery (MTTR)
* Change failure rate

### Deployment Artifacts

Each deployment includes:

* Build manifest (JSON)
* Version information
* Component change log
* Artifact checksums
* Deployment audit log

---

## ⚙️ Configuration

### Variable Groups

Create these in Azure DevOps Library:

1. **vg-shared-config** - Shared across all environments
2. **vg-dev-config** - DEV environment variables
3. **vg-int-config** - INT environment variables
4. **vg-prd-config** - PRD environment variables

See [Configuration README](config/README.md) for details.

### Environments

Create these in Azure DevOps:

* **DEV** - No approvals, automatic deployment
* **INT** - Optional approvals
* **PRD** - **REQUIRED** approvals (minimum 2 reviewers)

---

## 🔄 Rollback

See [Rollback Guide](docs/ROLLBACK_GUIDE.md) for detailed procedures.

**Quick Rollback:**

1. Navigate to previous successful build in Azure DevOps
2. Click "Rerun" on deployment stages
3. Artifact is immutable and available
4. Deploy previous version

---

## ❓ FAQ

**Q: How do I add a new environment variable?**  
A: Add to appropriate variable group in Azure DevOps Library. Never commit secrets.

**Q: How do I skip deployment for documentation-only changes?**  
A: The pipeline automatically skips deployment if only `docs/**` or `README.md` changed.

**Q: How do I test the pipeline locally?**  
A: Run `scripts/validate.ps1` for validation. Full pipeline testing requires Azure DevOps.

**Q: What if a production deployment fails?**  
A: Follow the [Rollback Guide](docs/ROLLBACK_GUIDE.md). Previous artifact is always available.

**Q: How do I add a new component to change detection?**  
A: Update `scripts/detect-changes.ps1` with new path pattern and output variable.

---

## 📝 License

MIT License - See [LICENSE](LICENSE) for details

---

## 🤝 Contributing

1. Follow the branching strategy
2. Write tests for new features
3. Update documentation
4. Ensure CI passes
5. Get code review approval

---

## 📧 Support

For questions or issues:

* **Technical**: [Your Team Email]
* **Production**: [Production Support]
* **Emergency**: [On-Call Engineer]

---

**Built with ❤️ for Azure Data Engineering**