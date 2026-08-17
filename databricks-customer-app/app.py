import os
import logging

import pandas as pd
import streamlit as st

from databricks import sql
from databricks.sdk.core import Config as DatabricksConfig

from config import load_environment, validate_config, get_database_path


# ---------------------------------------------------------
# Load Environment Configuration
# ---------------------------------------------------------

try:
    app_config = load_environment()
    validate_config()
except Exception as e:
    st.error(f"Configuration Error: {str(e)}")
    st.info("Please check your .env file and try again.")
    st.stop()

logger = logging.getLogger(__name__)


# ---------------------------------------------------------
# Application configuration
# ---------------------------------------------------------

st.set_page_config(
    page_title="Customer Management",
    page_icon="👥",
    layout="wide"
)

st.title(app_config.APP_TITLE)
st.caption(app_config.APP_DESCRIPTION)

if app_config.DEBUG_MODE:
    with st.expander("🔧 Debug Info"):
        st.write(f"**Environment:** {app_config.APP_ENV}")
        st.write(f"**Database:** {get_database_path()}")
        st.write(f"**Debug Mode:** {app_config.DEBUG_MODE}")


# ---------------------------------------------------------
# Databricks configuration
# ---------------------------------------------------------

bricks_config = DatabricksConfig(
    host=app_config.DATABRICKS_HOST,
    token=app_config.DATABRICKS_TOKEN
)


def get_connection():
    """
    Create and return a connection to Databricks SQL warehouse.
    
    Returns:
        sql.Connection: Connection to Databricks SQL warehouse
        
    Raises:
        Exception: If warehouse ID is not configured
    """
    warehouse_id = app_config.DATABRICKS_WAREHOUSE_ID

    if not warehouse_id:
        st.error("DATABRICKS_WAREHOUSE_ID is not configured.")
        st.stop()

    http_path = f"/sql/1.0/warehouses/{warehouse_id}"
    server_hostname = bricks_config.host

    if server_hostname.startswith("https://"):
        server_hostname = server_hostname.replace("https://", "")

    try:
        conn = sql.connect(
            server_hostname=server_hostname,
            http_path=http_path,
            credentials_provider=lambda: bricks_config.authenticate,
            _use_arrow_native_complex_types=False
        )
        logger.debug(f"Connected to Databricks warehouse: {warehouse_id}")
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to Databricks: {str(e)}")
        st.error(f"Database connection failed: {str(e)}")
        st.stop()


# ---------------------------------------------------------
# Read customer data
# ---------------------------------------------------------

def get_customers():
    """
    Fetch all customers from the configured database table.
    
    Returns:
        DataFrame: Customer data from the database
    """
    db_path = get_database_path()
    query = f"""
        SELECT
            customer_id,
            customer_name,
            email,
            country,
            segment,
            annual_revenue,
            created_date,
            updated_date
        FROM {db_path}
        ORDER BY customer_id
    """

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(query)
            result = cursor.fetchall_arrow().to_pandas()
            logger.debug(f"Fetched {len(result)} customers")
            return result
    except Exception as e:
        logger.error(f"Error fetching customers: {str(e)}")
        st.error(f"Failed to fetch customers: {str(e)}")
        st.stop()
    finally:
        conn.close()


# ---------------------------------------------------------
# Load data
# ---------------------------------------------------------

df = get_customers()


# ---------------------------------------------------------
# Metrics
# ---------------------------------------------------------

col1, col2, col3 = st.columns(3)

with col1:
    st.metric(
        "Total Customers",
        len(df)
    )

with col2:
    st.metric(
        "Countries",
        df["country"].nunique()
    )

with col3:
    st.metric(
        "Total Revenue",
        f"${df['annual_revenue'].sum():,.0f}"
    )


st.divider()


# ---------------------------------------------------------
# Search
# ---------------------------------------------------------

search = st.text_input(
    "🔎 Search Customer",
    placeholder="Enter customer name..."
)


if search:

    filtered_df = df[
        df["customer_name"]
        .str.contains(
            search,
            case=False,
            na=False
        )
    ]

else:

    filtered_df = df


# ---------------------------------------------------------
# Display
# ---------------------------------------------------------

st.subheader("Customer Data")

st.dataframe(
    filtered_df,
    use_container_width=True,
    hide_index=True
)


# ---------------------------------------------------------
# Add database INSERT
# ---------------------------------------------------------

def get_next_customer_id():
    """
    Generate the next customer ID.
    
    Returns:
        int: Next available customer ID
    """
    db_path = get_database_path()
    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                f"""
                    SELECT COALESCE(MAX(customer_id), 0) + 1 AS next_customer_id
                    FROM {db_path}
                """
            )
            result = cursor.fetchone()
            next_id = int(result[0]) if result and result[0] is not None else 1
            logger.debug(f"Next customer ID: {next_id}")
            return next_id
    except Exception as e:
        logger.error(f"Error getting next customer ID: {str(e)}")
        st.error(f"Failed to generate customer ID: {str(e)}")
        st.stop()
    finally:
        conn.close()


def add_customer(
    customer_name,
    email,
    country,
    segment,
    annual_revenue
):
    """
    Add a new customer to the database.
    
    Args:
        customer_name: Customer name
        email: Customer email
        country: Customer country
        segment: Customer segment
        annual_revenue: Annual revenue
    """
    customer_id = get_next_customer_id()
    db_path = get_database_path()
    conn = get_connection()

    try:
        query = f"""
            INSERT INTO {db_path}
            (
                customer_id,
                customer_name,
                email,
                country,
                segment,
                annual_revenue,
                created_date,
                updated_date
            )
            VALUES
            (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                current_date(),
                current_timestamp()
            )
        """

        with conn.cursor() as cursor:
            cursor.execute(
                query,
                (
                    customer_id,
                    customer_name,
                    email,
                    country,
                    segment,
                    float(annual_revenue)
                )
            )

        conn.commit()
        logger.info(f"Customer added: {customer_name} (ID: {customer_id})")

    except Exception as e:
        logger.error(f"Error adding customer: {str(e)}")
        st.error(f"Failed to add customer: {str(e)}")
    finally:
        conn.close()


# ---------------------------------------------------------
# Add Customer form
# ---------------------------------------------------------

st.sidebar.header("➕ Add Customer")

with st.sidebar.form("customer_form"):

    customer_name = st.text_input(
        "Customer Name"
    )

    email = st.text_input(
        "Email"
    )

    country = st.selectbox(
        "Country",
        [
            "India",
            "USA",
            "UK",
            "Singapore",
            "Canada",
            "Australia"
        ]
    )

    segment = st.selectbox(
        "Segment",
        [
            "Enterprise",
            "SMB",
            "Retail"
        ]
    )

    annual_revenue = st.number_input(
        "Annual Revenue",
        min_value=0.0,
        step=1000.0
    )

    submitted = st.form_submit_button(
        "Add Customer"
    )

    if submitted:
        if not customer_name or not email:
            st.sidebar.error("Customer name and email are required.")
        else:
            with st.spinner("Adding customer and refreshing data..."):
                add_customer(
                    customer_name,
                    email,
                    country,
                    segment,
                    annual_revenue
                )

            st.sidebar.success("Customer added successfully.")
            st.rerun()
