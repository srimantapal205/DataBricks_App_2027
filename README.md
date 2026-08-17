# Customer Management App
Build a small Customer Management App that can:

- Display customer data
- Search customers
- Filter customers
- Add a customer
- Edit a customer
- Delete a customer
- Save changes into a Delta table
- Use Unity Catalog
- Connect through a Databricks SQL Warehouse
- Use the Databricks App's service principal
- Later add authentication, audit logging, data quality and AI


This follows Microsoft's current Databricks Apps + Streamlit pattern: the app can read and modify Unity Catalog tables, with the app service principal requiring appropriate SELECT/MODIFY permissions and CAN USE on the SQL warehouse.


```
                         USER
                           |
                           v
                +---------------------+
                |   Databricks App    |
                |      Streamlit      |
                +----------+----------+
                           |
                           | OAuth /
                           | App Identity
                           v
                +---------------------+
                | Databricks SQL      |
                | Warehouse           |
                +----------+----------+
                           |
                           v
                  Unity Catalog
                           |
                           v
                +---------------------+
                | Delta Table         |
                | customer_management  |
                +---------------------+
                           |
                           v
                       ADLS Gen2

```

### application will eventually look approximately like:

```
┌─────────────────────────────────────────────────────────────┐
│              CUSTOMER MANAGEMENT APP                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Customer ID     [____________]                            │
│  Name            [____________]                            │
│  Email           [____________]                            │
│  Country         [India ▼]                                 │
│  Segment         [Enterprise ▼]                            │
│  Revenue         [____________]                            │
│                                                             │
│             [ Add Customer ]                                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ Search Customer                                             │
│ [______________] [Search]                                  │
│                                                             │
│ ID       Name        Country      Segment      Revenue      │
│ 1001     ABC Ltd     India        Enterprise   120000      │
│ 1002     XYZ Ltd     USA          Retail        85000      │
│ 1003     PQR Ltd     India        Enterprise   240000      │
│                                                             │
│ [Edit] [Delete]                                             │
└─────────────────────────────────────────────────────────────┘

```

