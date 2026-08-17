# Environment Configuration Guide

This guide explains how to manage environment-specific configurations for the Customer Management App using `.env` files.

## Overview

The application supports three environment configurations:
- **DEV** - Development environment
- **INT** - Integration/Staging environment  
- **PRD** - Production environment

Each environment has its own `.env` file containing specific configuration values.

## Files

### `.env.example`
**Template file** - Shows all available configuration variables. 
- **Status**: Committed to Git
- **Purpose**: Reference for creating new environment files
- **Action**: Copy this file to create `.env.dev`, `.env.int`, or `.env.prd`

```bash
cp .env.example .env.dev
```

### `.env.dev`
**Development environment** - Uses your DEV Databricks workspace
- **Status**: NOT committed (in .gitignore)
- **Contains**: DEV credentials and settings
- **Debug Mode**: Enabled (more verbose logging)

### `.env.int`
**Integration environment** - Uses your INT Databricks workspace
- **Status**: NOT committed (in .gitignore)
- **Contains**: INT credentials and settings
- **Debug Mode**: Disabled

### `.env.prd`
**Production environment** - Uses your PROD Databricks workspace
- **Status**: NOT committed (in .gitignore)
- **Contains**: PROD credentials and settings
- **Debug Mode**: Disabled (minimal logging)

## Configuration Variables

### Databricks Configuration

```env
# Databricks Workspace Host URL
DATABRICKS_HOST=https://adb-xxx.cloud.databricks.com

# Databricks Personal Access Token
DATABRICKS_TOKEN=dapi...

# SQL Warehouse ID
DATABRICKS_WAREHOUSE_ID=9ddd8e60ba810fdd
```

### Catalog Configuration

```env
# Required
CATALOG_NAME=demo_catalog

# Optional for environment-specific table selection
SCHEMA_NAME=customer_app
TABLE_NAME=customers
```

### Application Configuration

```env
# Environment name (DEV, INT, PRD)
APP_ENV=DEV

# App title shown in Streamlit
APP_TITLE=👥 Customer Management App (DEV)

# App description shown in Streamlit
APP_DESCRIPTION=Azure Databricks + Streamlit + Unity Catalog [Development]

# Enable debug mode (shows debug info in app)
DEBUG_MODE=true

# Log level (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=DEBUG
```

### Streamlit Configuration

```env
STREAMLIT_GATHER_USAGE_STATS=false
```

## Usage

### Setup Steps

1. **Create development environment file:**
   ```bash
   cp .env.example .env.dev
   ```

2. **Edit `.env.dev` with your DEV credentials:**
   ```bash
   # Edit the following in .env.dev:
   DATABRICKS_HOST=https://your-dev-workspace.cloud.databricks.com
   DATABRICKS_TOKEN=dapi...
   DATABRICKS_WAREHOUSE_ID=your-dev-warehouse-id
   ```

3. **Repeat for INT and PRD environments** (if needed):
   ```bash
   cp .env.example .env.int
   cp .env.example .env.prd
   ```

### Running the App

#### Run with specific environment (using PowerShell)

```powershell
# Set environment variable to load .env.dev
$env:APP_ENV = "DEV"

# Run the app
streamlit run app.py
```

#### Or run with default DEV environment
```powershell
# The app defaults to DEV if APP_ENV is not set
streamlit run app.py
```

#### Run with INT environment
```powershell
$env:APP_ENV = "INT"
streamlit run app.py
```

#### Run with PRD environment
```powershell
$env:APP_ENV = "PRD"
streamlit run app.py
```

### Verify Configuration

Test if your configuration loads correctly:

```bash
# Test DEV environment
python config.py DEV

# Test INT environment
python config.py INT

# Test PRD environment
python config.py PRD
```

You should see output like:
```
✅ Configuration loaded successfully!
Environment: DEV
Database: demo_catalog.customer_app.customers
Debug Mode: True
```

## How It Works

1. **Load Environment**: The app calls `load_environment()` which:
   - Checks the `APP_ENV` environment variable (defaults to `DEV`)
   - Loads variables from the corresponding `.env.{env}` file
   - Validates that all required variables are present

2. **Configuration Class**: The `Config` class holds all environment variables:
   ```python
   from config import load_environment, get_database_path
   
   app_config = load_environment()  # Loads from .env.dev (default)
   print(app_config.DATABRICKS_HOST)
   print(get_database_path())  # Outputs: demo_catalog.customer_app.customers
   ```

3. **Use in App**: All app functions use `app_config` to access settings:
   ```python
   warehouse_id = app_config.DATABRICKS_WAREHOUSE_ID
   db_path = get_database_path()  # Combines CATALOG_NAME.SCHEMA_NAME.TABLE_NAME
   ```

4. **Debug Mode**: When `DEBUG_MODE=true`, the app shows a debug panel:
   - Environment name
   - Database path
   - Debug status

## Security Best Practices

⚠️ **IMPORTANT**: Never commit `.env` files with credentials!

- ✅ Commit: `.env.example` (template only)
- ❌ Do NOT commit: `.env.dev`, `.env.int`, `.env.prd` (have real credentials)
- ✅ Verified: `.gitignore` already excludes these files

### To add new environment files safely:

1. Create the file from template: `cp .env.example .env.myenv`
2. Edit with your credentials
3. The file is automatically ignored by Git
4. Share credentials through secure channel (password manager, secrets vault, etc.)

## Troubleshooting

### "Configuration Error: Environment file not found"
- **Cause**: The `.env.{env}` file doesn't exist
- **Solution**: Create it from `.env.example`:
  ```bash
  cp .env.example .env.dev
  ```

### "Missing required configuration fields"
- **Cause**: Some required variables are missing or empty in `.env` file
- **Solution**: Check your `.env` file and ensure all fields are filled in

### "MALFORMED_REQUEST: Path /sql/1.0/warehouses/..."
- **Cause**: Warehouse ID is incorrect (likely the display name instead of ID)
- **Solution**: Use the actual warehouse ID, not the display name
  - Go to Databricks > SQL > Warehouses
  - Click on your warehouse and find the ID in the URL or details

### Debug mode not showing
- **Cause**: `DEBUG_MODE` is set to `false`
- **Solution**: Set `DEBUG_MODE=true` in your `.env` file

## Advanced: Using Environment-Specific Database Tables

You can have different tables in each environment:

```env
# .env.dev
CATALOG_NAME=demo_catalog
SCHEMA_NAME=customer_app_dev
TABLE_NAME=customers

# .env.int
CATALOG_NAME=demo_catalog
SCHEMA_NAME=customer_app_int
TABLE_NAME=customers

# .env.prd
CATALOG_NAME=prod_catalog
SCHEMA_NAME=customer_app
TABLE_NAME=customers
```

The `get_database_path()` function will automatically construct the correct path:
- DEV: `demo_catalog.customer_app_dev.customers`
- INT: `demo_catalog.customer_app_int.customers`
- PRD: `prod_catalog.customer_app.customers`

## Next Steps

1. ✅ Create `.env.dev` from `.env.example`
2. ✅ Add your DEV Databricks credentials
3. ✅ Test with: `python config.py DEV`
4. ✅ Run the app: `streamlit run app.py`
5. ✅ Create `.env.int` and `.env.prd` for other environments (optional)

---

For more information, see:
- [Databricks Documentation](https://docs.databricks.com/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- `config.py` - Configuration loader implementation
