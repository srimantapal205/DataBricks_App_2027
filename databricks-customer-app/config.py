"""
Configuration loader for managing environment-specific settings.
Loads variables from .env files based on the APP_ENV environment variable.
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import logging


VALID_ENVIRONMENTS = ["DEV", "INT", "PRD"]
REQUIRED_FIELDS = [
    "DATABRICKS_HOST",
    "DATABRICKS_TOKEN",
    "DATABRICKS_WAREHOUSE_ID",
    "CATALOG_NAME",
]


def get_runtime_env_name() -> str:
    """Resolve the active environment from OS variables or defaults."""
    env_name = (
        os.getenv("APP_ENV")
        or os.getenv("ENVIRONMENT")
        or os.getenv("TARGET_ENVIRONMENT")
        or os.getenv("DEPLOY_ENV")
        or "DEV"
    )
    return env_name.upper()


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Base configuration class with defaults"""
    
    def __init__(self):
        """Initialize configuration by reading environment variables."""
        # Databricks Configuration
        self.DATABRICKS_HOST = os.getenv("DATABRICKS_HOST", "")
        self.DATABRICKS_TOKEN = os.getenv("DATABRICKS_TOKEN", "")
        self.DATABRICKS_WAREHOUSE_ID = os.getenv("DATABRICKS_WAREHOUSE_ID", "")
        
        # Catalog configuration (required)
        # Schema/table default to a common development pattern and can be overridden.
        self.CATALOG_NAME = os.getenv("CATALOG_NAME", "").strip()
        self.SCHEMA_NAME = os.getenv("SCHEMA_NAME", "customer_app").strip() or "customer_app"
        self.TABLE_NAME = os.getenv("TABLE_NAME", "customers").strip() or "customers"
        
        # Streamlit Configuration
        self.STREAMLIT_GATHER_USAGE_STATS = os.getenv("STREAMLIT_GATHER_USAGE_STATS", "false").lower() == "true"
        
        # Application Configuration
        self.APP_ENV = os.getenv("APP_ENV", "DEV")
        self.APP_TITLE = os.getenv("APP_TITLE", "Customer Management App")
        self.APP_DESCRIPTION = os.getenv("APP_DESCRIPTION", "Azure Databricks + Streamlit + Unity Catalog")
        self.DEBUG_MODE = os.getenv("DEBUG_MODE", "false").lower() == "true"
        self.LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")


def load_environment(env_name: str = None) -> Config:
    """
    Load environment configuration from OS variables and optional .env file.
    This supports both local development and Azure DevOps pipeline variable groups.
    
    Args:
        env_name: Environment name (DEV, INT, PRD). If None, checks APP_ENV/ENVIRONMENT and defaults to DEV.
    
    Returns:
        Config object with loaded environment variables
    
    Raises:
        FileNotFoundError: If the specified .env file doesn't exist and no runtime values are configured
        ValueError: If invalid environment name is provided
    """
    
    if env_name is None:
        env_name = get_runtime_env_name()
    else:
        env_name = env_name.upper()

    if env_name not in VALID_ENVIRONMENTS:
        raise ValueError(
            f"Invalid environment '{env_name}'. Must be one of: {', '.join(VALID_ENVIRONMENTS)}"
        )

    env_file = Path(__file__).parent / f".env.{env_name.lower()}"
    has_runtime_values = any(os.getenv(key) for key in REQUIRED_FIELDS)

    if env_file.exists():
        load_dotenv(env_file, override=True)
        has_runtime_values = True

    if not has_runtime_values:
        raise FileNotFoundError(
            f"No environment configuration found for {env_name}.\n"
            f"Expected either .env.{env_name.lower()} or Azure DevOps/OS environment variables."
        )

    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, log_level, logging.INFO),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    logger = logging.getLogger(__name__)
    logger.info(f"Loaded environment: {env_name} from {'runtime variables' if not env_file.exists() else env_file}")

    return Config()


def get_database_path() -> str:
    """
    Get the full database path in format: catalog.schema.table.

    Schema and table are optional overrides; if omitted, sensible defaults are used
    so a valid Unity Catalog table name is still resolved.
    """
    config = Config()
    catalog = config.CATALOG_NAME.strip()
    schema = config.SCHEMA_NAME.strip() or "customer_app"
    table = config.TABLE_NAME.strip() or "customers"

    return f"{catalog}.{schema}.{table}"


def validate_config() -> bool:
    """
    Validate that all required configuration is present.
    
    Returns:
        bool: True if all required config is present
    
    Raises:
        ValueError: If any required configuration is missing
    """
    config = Config()
    
    required_fields = {
        "DATABRICKS_HOST": config.DATABRICKS_HOST,
        "DATABRICKS_TOKEN": config.DATABRICKS_TOKEN,
        "DATABRICKS_WAREHOUSE_ID": config.DATABRICKS_WAREHOUSE_ID,
        "CATALOG_NAME": config.CATALOG_NAME,
    }
    
    missing_fields = [field for field, value in required_fields.items() if not value]
    
    if missing_fields:
        raise ValueError(
            f"Missing required configuration fields: {', '.join(missing_fields)}\n"
            f"Please check your .env file or environment variables."
        )
    
    logger = logging.getLogger(__name__)
    logger.info("Configuration validation passed")
    return True


if __name__ == "__main__":
    # Test configuration loading
    try:
        env_name = sys.argv[1] if len(sys.argv) > 1 else None
        config = load_environment(env_name)
        validate_config()
        
        print(f"\n✅ Configuration loaded successfully!")
        print(f"Environment: {config.APP_ENV}")
        print(f"Database: {get_database_path()}")
        print(f"Debug Mode: {config.DEBUG_MODE}")
        
    except Exception as e:
        print(f"\n❌ Configuration error: {e}")
        sys.exit(1)
