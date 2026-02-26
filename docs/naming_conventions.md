# 📏 Data Warehouse Naming Conventions

This document outlines the standard naming conventions applied throughout the Data Warehouse project. Adhering to these rules ensures consistency, readability, and ease of maintenance for both Data Engineers and BI Analysts.

---

## 🏗️ General Rules
1. **Case Style**: All database objects (tables, columns, schemas) must use `snake_case`.
2. **Reserved Words**: Strictly avoid SQL reserved keywords (e.g., `SELECT`, `TABLE`, `DATE`, `ORDER`) as object names.
3. **No Special Characters**: Use only alphanumeric characters and underscores.
4. **Consistency**: Once an entity is named in Bronze, that name should carry through to Silver for traceability.

---

## 📂 Schema & Object Naming

### 1. Bronze Layer (Raw)
* **Table Pattern**: `<source_system>_<entity_name>`
* **Purpose**: Identifies exactly where the data originated.
* **Example**: `bronze.crm_cust_info`, `bronze.erp_loc_a101`

### 2. Silver Layer (Cleansed)
* **Table Pattern**: `<source_system>_<entity_name>`
* **Purpose**: Maintains the same name as Bronze for easy lineage tracking, but resides in the `Silver` schema to indicate it is "clean."
* **Example**: `Silver.crm_sales_details`, `Silver.erp_cust_az12`

### 3. Gold Layer (Reporting)
* **View Pattern**: `<category>_<entity_name>`
* **Purpose**: Organized by business subject area rather than technical source.
* **Example**: `gold.dim_customers`, `gold.fact_sales`

### 4. Internal Table Engineering
* **Pattern**: `<dwh>_<name>`
* **Purpose**: Used for internal engineering tables or metadata logs.
* **Example**: `dwh_load_logs`, `dwh_watermark_table`

---

##  kolom Column Naming

### Bronze & Silver (Engineering Focus)
* Columns use technical prefixes to prevent ambiguity during complex joins.
* **Example**: `cst_id`, `prd_key`, `sls_order_dt`.

### Gold (User Focus)
* Columns use **friendly, descriptive names** for end-users and BI tools.
* **Example**: `customer_id`, `product_number`, `order_date`.

---

## ⚙️ Stored Procedures
* **Pattern**: `<schema>.load_<layer>`
* **Purpose**: Clearly identifies which layer of the warehouse the procedure populates.
* **Example**: 
    * `bronze.load_bronze`
    * `Silver.load_silver`

---

## 🛠️ Metadata Columns
Every table in the Silver layer must include the following audit column:
* `dwh_create_date`: `DATETIME2 DEFAULT GETDATE()` — Records the timestamp when the row was processed into the warehouse.

---

## 🚩 Importance of snake_case
While SQL Server is often case-insensitive, `snake_case` is used to maintain compatibility with modern data tools (like Python, dbt, or Spark) that may be integrated into this pipeline in the future.
