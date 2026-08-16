# Customer Management App
Build a small Customer Management App that can:

Display customer data
Search customers
Filter customers
Add a customer
Edit a customer
Delete a customer
Save changes into a Delta table
Use Unity Catalog
Connect through a Databricks SQL Warehouse
Use the Databricks App's service principal
Later add authentication, audit logging, data quality and AI

This follows Microsoft's current Databricks Apps + Streamlit pattern: the app can read and modify Unity Catalog tables, with the app service principal requiring appropriate SELECT/MODIFY permissions and CAN USE on the SQL warehouse.
