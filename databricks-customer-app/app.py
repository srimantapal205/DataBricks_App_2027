import os

import pandas as pd
import streamlit as st

from databricks import sql
from databricks.sdk.core import Config


# ---------------------------------------------------------
# Application configuration
# ---------------------------------------------------------

st.set_page_config(
    page_title="Customer Management",
    page_icon="👥",
    layout="wide"
)

st.title("👥 Customer Management App")
st.caption("Azure Databricks + Streamlit + Unity Catalog")


# ---------------------------------------------------------
# Databricks configuration
# ---------------------------------------------------------

cfg = Config()


def get_connection():

    warehouse_id = os.getenv("DATABRICKS_WAREHOUSE_ID")

    if not warehouse_id:
        st.error("DATABRICKS_WAREHOUSE_ID is not configured.")
        st.stop()

    http_path = f"/sql/1.0/warehouses/{warehouse_id}"

    server_hostname = cfg.host

    if server_hostname.startswith("https://"):
        server_hostname = server_hostname.replace("https://", "")

    return sql.connect(
        server_hostname=server_hostname,
        http_path=http_path,
        credentials_provider=lambda: cfg.authenticate,
        _use_arrow_native_complex_types=False
    )


# ---------------------------------------------------------
# Read customer data
# ---------------------------------------------------------

def get_customers():

    query = """
        SELECT
            customer_id,
            customer_name,
            email,
            country,
            segment,
            annual_revenue,
            created_date,
            updated_date
        FROM demo_catalog.customer_app.customers
        ORDER BY customer_id
    """

    conn = get_connection()

    try:

        with conn.cursor() as cursor:

            cursor.execute(query)

            return cursor.fetchall_arrow().to_pandas()

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

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                    SELECT COALESCE(MAX(customer_id), 0) + 1 AS next_customer_id
                    FROM demo_catalog.customer_app.customers
                """
            )
            result = cursor.fetchone()
            return int(result[0]) if result and result[0] is not None else 1

    finally:
        conn.close()


def add_customer(
    customer_name,
    email,
    country,
    segment,
    annual_revenue
):

    customer_id = get_next_customer_id()

    conn = get_connection()

    try:

        query = """
            INSERT INTO demo_catalog.customer_app.customers
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
