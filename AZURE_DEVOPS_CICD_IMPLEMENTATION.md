# Azure DevOps CI/CD Implementation Guide

This document explains how to implement Azure DevOps CI/CD for the Databricks Customer Management App in a step-by-step manner.

## 1. Project overview

This project is a Streamlit application that connects to Azure Databricks SQL Warehouse and reads/writes data from Unity Catalog tables.

Key files in the project:
- app.py - Streamlit UI and business logic
- config.py - loads environment variables and validates required settings
- requirements.txt - Python dependencies
- .env.dev, .env.int, .env.prd - environment-specific local settings
- azure-pipelines.yml - Azure DevOps CI pipeline

The application supports three environment modes:
- DEV
- INT
- PRD

The configuration loader reads values from:
1. Azure DevOps pipeline variables / variable groups
2. local environment variables
3. .env.<environment> file as fallback

This ensures the app can run both locally and in Azure DevOps without hard-coding secrets.

## 2. Current project structure

Project root:
- databricks-customer-app/
  - app.py
  - config.py
  - requirements.txt
  - .env.example
  - .env.dev
  - .env.int
  - .env.prd
  - README.md
  - ENVIRONMENT_SETUP.md

The CI/CD pipeline sits at the project root as:
- azure-pipelines.yml

## 3. Why Azure DevOps is required

Azure DevOps is used for:
- continuous integration
- configuration validation
- dependency installation
- environment validation before deployment
- centralized secret management through variable groups
- automated quality checks for the Streamlit app

This project is a Python app, so Azure DevOps hosted agents are ideal for running the build and smoke tests.

## 4. Prerequisites

Before configuring Azure DevOps, confirm the following:

### 4.1 Git repository
- The project is pushed to Azure Repos or GitHub
- The branch is available to Azure Pipelines

### 4.2 Python version
- Use Python 3.11
- The app has required dependencies in requirements.txt

### 4.3 Databricks access
- Databricks workspace URL is available
- PAT token is valid
- SQL warehouse ID is valid
- Unity Catalog catalog, schema, and table names are known

### 4.4 Azure DevOps access
- Azure DevOps organization is available
- User has permission to create Pipelines and Variable Groups

## 5. Environment configuration model

The app uses the following configuration values:

- APP_ENV
- DATABRICKS_HOST
- DATABRICKS_TOKEN
- DATABRICKS_WAREHOUSE_ID
- CATALOG_NAME
- SCHEMA_NAME
- TABLE_NAME
- APP_TITLE
- APP_DESCRIPTION
- DEBUG_MODE
- LOG_LEVEL
- STREAMLIT_GATHER_USAGE_STATS

These are validated inside config.py before the app starts.

The config loader logic is:
- check APP_ENV / ENVIRONMENT / DEPLOY_ENV
- validate environment name (DEV, INT, PRD)
- load .env.<env> if it exists
- read runtime variables from Azure DevOps or OS environment
- validate required values

This is important because Azure DevOps pipelines inject variables into the build environment instead of using local .env files.

## 6. Step-by-step Azure DevOps setup

### Step 1: Create a variable group

In Azure DevOps:
1. Open Azure DevOps project
2. Go to Pipelines > Library
3. Select Variable groups
4. Create a new variable group named:
   databricks-customer-app

Add the following variables:

- APP_ENV = DEV
- DATABRICKS_HOST = https://your-workspace.cloud.databricks.com
- DATABRICKS_TOKEN = dapi...
- DATABRICKS_WAREHOUSE_ID = 9ddd8e60ba810fdd
- CATALOG_NAME = demo_catalog
- SCHEMA_NAME = customer_app
- TABLE_NAME = customers
- APP_TITLE = Customer Management App
- APP_DESCRIPTION = Azure Databricks + Streamlit + Unity Catalog
- DEBUG_MODE = true
- LOG_LEVEL = DEBUG
- STREAMLIT_GATHER_USAGE_STATS = false

Important:
- Use Secure variables for secrets like DATABRICKS_TOKEN
- Mark sensitive values as secret
- You can create separate variable groups for DEV, INT, and PRD if needed

### Step 2: Link the variable group to the pipeline

In the pipeline YAML, add:

variables:
- group: databricks-customer-app

This allows the pipeline to access the values automatically.

### Step 3: Configure the repository path

The project contains an app folder inside the repo root. The pipeline uses:

- APP_DIR = databricks-customer-app/databricks-customer-app

If your repo structure changes, update APP_DIR accordingly.

### Step 4: Create the pipeline YAML

The exact pipeline file is already prepared as azure-pipelines.yml.

The pipeline contains three main stages of work:
1. Install dependencies
2. Validate environment configuration
3. Smoke test the Streamlit app

## 7. Exact Azure DevOps pipeline YAML

Use the following YAML in Azure DevOps:

```yaml
trigger:
- main

pr:
- main

pool:
  vmImage: ubuntu-latest

variables:
- group: databricks-customer-app
- name: PYTHON_VERSION
  value: '3.11'
- name: APP_DIR
  value: 'databricks-customer-app/databricks-customer-app'

steps:
- checkout: self

- task: UsePythonVersion@0
  displayName: 'Use Python $(PYTHON_VERSION)'
  inputs:
    versionSpec: '$(PYTHON_VERSION)'

- script: |
    python -m pip install --upgrade pip
    python -m pip install --upgrade setuptools wheel
  displayName: 'Upgrade pip and packaging tools'

- script: |
    cd '$(Build.SourcesDirectory)/$(APP_DIR)'
    python -m pip install -r requirements.txt
  displayName: 'Install Python dependencies'

- script: |
    cd '$(Build.SourcesDirectory)/$(APP_DIR)'
    python config.py "$(APP_ENV)"
  displayName: 'Validate Databricks configuration'
  env:
    APP_ENV: $(APP_ENV)
    DATABRICKS_HOST: $(DATABRICKS_HOST)
    DATABRICKS_TOKEN: $(DATABRICKS_TOKEN)
    DATABRICKS_WAREHOUSE_ID: $(DATABRICKS_WAREHOUSE_ID)
    CATALOG_NAME: $(CATALOG_NAME)
    SCHEMA_NAME: $(SCHEMA_NAME)
    TABLE_NAME: $(TABLE_NAME)
    APP_TITLE: $(APP_TITLE)
    APP_DESCRIPTION: $(APP_DESCRIPTION)
    DEBUG_MODE: $(DEBUG_MODE)
    LOG_LEVEL: $(LOG_LEVEL)
    STREAMLIT_GATHER_USAGE_STATS: $(STREAMLIT_GATHER_USAGE_STATS)

- script: |
    cd '$(Build.SourcesDirectory)/$(APP_DIR)'
    python -m streamlit run app.py --server.headless true --server.port 8501 &
    sleep 20
    python - <<'PY'
import urllib.request
url = 'http://127.0.0.1:8501'
with urllib.request.urlopen(url, timeout=20) as response:
    print('HTTP status:', response.status)
    print('Response ok:', response.status == 200)
PY
  displayName: 'Smoke test Streamlit app'
  env:
    APP_ENV: $(APP_ENV)
    DATABRICKS_HOST: $(DATABRICKS_HOST)
    DATABRICKS_TOKEN: $(DATABRICKS_TOKEN)
    DATABRICKS_WAREHOUSE_ID: $(DATABRICKS_WAREHOUSE_ID)
    CATALOG_NAME: $(CATALOG_NAME)
    SCHEMA_NAME: $(SCHEMA_NAME)
    TABLE_NAME: $(TABLE_NAME)
    APP_TITLE: $(APP_TITLE)
    APP_DESCRIPTION: $(APP_DESCRIPTION)
    DEBUG_MODE: $(DEBUG_MODE)
    LOG_LEVEL: $(LOG_LEVEL)
    STREAMLIT_GATHER_USAGE_STATS: $(STREAMLIT_GATHER_USAGE_STATS)
```

## 8. What this pipeline validates

The pipeline checks the following:
- Python dependency installation works
- requirements.txt is complete
- config.py can read values from Azure DevOps variables
- required Databricks configuration values are present
- the app can start in headless mode
- the app responds on port 8501 without crashing

This is a good CI implementation for a Streamlit app before moving to a release pipeline.

## 9. How the app reads Azure DevOps variables

The configuration model in config.py is designed so runtime environment variables override local .env settings.

This allows Azure DevOps to inject values such as:
- DATABRICKS_HOST
- DATABRICKS_TOKEN
- DATABRICKS_WAREHOUSE_ID
- CATALOG_NAME
- SCHEMA_NAME
- TABLE_NAME

The app does not depend on a fixed .env file at runtime.

## 10. Pipeline execution flow

### 10.1 Trigger rules
The pipeline runs when:
- code is pushed to main
- a pull request is created against main

### 10.2 Build steps
1. Install Python
2. Upgrade packaging tools
3. Install project dependencies
4. Run configuration validation using python config.py
5. Start Streamlit with headless mode
6. Hit localhost:8501 to ensure the app is accessible

### 10.3 Failure conditions
The pipeline fails if:
- one required variable is missing
- the Databricks host/token is invalid
- the warehouse ID is wrong
- the app startup crashes
- the app does not respond on the expected port

## 11. Recommended Azure DevOps security configuration

To avoid leaks:
- store DATabricks token in a secure variable group
- create separate variable groups for DEV, INT, PRD
- restrict pipeline permissions to project contributors
- use environment approvals for production releases
- do not keep secrets in code or in commit history

## 12. Recommended environment strategy

For real project delivery, create three environments:

### DEV
- lower-risk testing
- use development Databricks workspace
- enable debug mode

### INT
- integration testing
- validate app against staged data
- confirm access to Unity Catalog tables

### PRD
- production settings
- disable debug mode
- use minimal logging

## 13. Suggested production enhancement

If you want a real CD flow, add deployment stages:

- Stage 1: Build and test
- Stage 2: Deploy to DEV
- Stage 3: Manual approval for INT
- Stage 4: Production approval and deployment

Example release model:
- Build pipeline validates code
- Release pipeline deploys the final package to environment-specific settings
- Variable groups provide environment-specific connection information

## 14. Troubleshooting common pipeline issues

### Issue: Missing required configuration fields
Cause:
- variable group values are not mapped correctly
- pipeline env variables are not passed to the script

Fix:
- confirm variable names exactly match the app requirements
- verify variable group is linked to the pipeline
- ensure secret variables are available to the pipeline

### Issue: Databricks connection failed
Cause:
- DATABRICKS_HOST is incorrect
- token is expired
- warehouse ID is wrong

Fix:
- validate workspace URL format
- confirm PAT is valid
- confirm SQL Warehouse ID is not the display name

### Issue: Streamlit app does not start
Cause:
- missing package installation
- port conflict
- Python version mismatch

Fix:
- confirm requirements.txt includes all packages
- run pip install -r requirements.txt in the app folder
- ensure headless mode is enabled

### Issue: pipeline passes locally but fails in Azure DevOps
Cause:
- environment variables are not exported to the script
- variables are not marked as available to the pipeline stage

Fix:
- set env block in each script task
- confirm the variable group is linked
- inspect pipeline logs in Azure DevOps

## 15. Final implementation summary

The implemented solution uses:
- Azure DevOps Pipelines for CI validation
- Azure DevOps Variable Groups for secrets and configuration
- Python validation script to check config before runtime
- Streamlit smoke tests to confirm the app starts successfully

This gives a secure, repeatable, and environment-aware CI/CD setup for the Databricks Customer Management App.

## 16. Recommended next steps

1. Create the variable group in Azure DevOps
2. Link the variable group to the pipeline
3. Push the repository and run the pipeline
4. Verify the configuration step succeeds
5. Confirm the app smoke test passes
6. Add separate DEV, INT, and PRD variable groups as the project matures

## 17. Conclusion

The project is already structured to support Azure DevOps with environment-driven configuration. The implementation is straightforward, secure, and aligned with modern DevOps practices for Python + Databricks applications.

This solution is suitable for:
- developer validation
- integration testing
- production-ready delivery pipelines
- secure management of Databricks credentials
