# 📚 Data Warehouse Catalog: Gold Layer (Reporting)

This document provides a detailed description of the final reporting views available in the **Gold Layer**. These views are optimized for Power BI, Tableau, and Excel reporting, following a **Star Schema** architecture.

---

## 👤 View: `gold.dim_customers`
**Description:** Contains a "Single View of the Truth" for all customers, merging data from CRM and ERP systems. It includes demographic details and unique reporting keys.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **customer_key** | `INT` | **Surrogate Key:** Unique identifier for reporting (Auto-generated). |
| **customer_id** | `INT` | Original ID from the CRM system. |
| **customer_number** | `NVARCHAR(50)` | Business key used to link CRM and ERP records. |
| **first_name** | `NVARCHAR(50)` | Customer's first name (Cleansed/Trimmed). |
| **last_name** | `NVARCHAR(50)` | Customer's last name (Cleansed/Trimmed). |
| **country** | `NVARCHAR(50)` | Standardized country name (e.g., 'United States' instead of 'US'). |
| **marital_status**| `NVARCHAR(50)` | Marital status: 'Married', 'Single', or 'n/a'. |
| **gender** | `NVARCHAR(50)` | Standardized gender: 'Male', 'Female', or 'n/a'. (Priority: CRM). |
| **birthdate** | `DATE` | Customer's date of birth (Validated for future/unrealistic dates). |
| **create_date** | `DATE` | Date the customer record was first created in the source system. |

---

## 📦 View: `gold.dim_products`
**Description:** A dimension table containing all products. This view is filtered to show only **current active products** (historical versions are excluded).

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **product_key** | `INT` | **Surrogate Key:** Unique identifier for reporting (Auto-generated). |
| **product_id** | `INT` | Original Product ID from the CRM system. |
| **product_number** | `NVARCHAR(50)` | Unique product code/SKU. |
| **product_name** | `NVARCHAR(50)` | Full name of the product. |
| **category_id** | `NVARCHAR(50)` | Extracted category code from the product key. |
| **category** | `NVARCHAR(50)` | High-level product category (e.g., Components, Bikes). |
| **sub_category** | `NVARCHAR(50)` | Detailed product sub-category. |
| **maintenance** | `VARCHAR(50)` | Indicates if the product requires maintenance. |
| **cost** | `INT` | The standardized cost of the product (Nulls replaced with 0). |
| **product_line** | `NVARCHAR(50)` | Full name of the product line (e.g., 'Mountain', 'Road'). |
| **start_date** | `DATE` | The date this product version became active. |

---

## 💰 View: `gold.fact_sales`
**Description:** The central fact table containing all sales transactions. It links to the customer and product dimensions via surrogate keys.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| **order_number** | `NVARCHAR(50)` | Unique identifier for the sales order. |
| **product_key** | `INT` | **Foreign Key:** Links to `gold.dim_products`. |
| **customer_key** | `INT` | **Foreign Key:** Links to `gold.dim_customers`. |
| **order_date** | `DATE` | The date the order was placed. |
| **shipping_date**| `DATE` | The date the order was shipped. |
| **due_date** | `DATE` | The date the payment or delivery is due. |
| **sales** | `INT` | **Measure:** Total sales amount (Verified: Quantity * Price). |
| **quantity** | `INT` | **Measure:** Number of units sold. |
| **price** | `INT` | **Measure:** Unit price of the product at the time of sale. |

---

## 🛠️ Data Quality Rules applied to Gold Layer:
1. **Deduplication:** CRM Customers are deduplicated using `ROW_NUMBER()` to ensure one record per `cst_id`.
2. **Standardization:** Gender and Marital Status codes are expanded to full words for readability.
3. **Integration:** ERP and CRM sources are joined; where data conflicts exist (like Gender), CRM is treated as the Master source.
4. **Accuracy:** Sales totals in `fact_sales` are recalculated if the source data is null or mathematically inconsistent.
