/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
PURPOSE:
    Initializes the Gold layer by creating final reporting views.
    These views represent the 'Star Schema' architecture, consisting of 
    Dimensions (Customers, Products) and a Fact table (Sales).
    
    The Gold layer is optimized for:
    - Business Intelligence (BI) tools (Power BI, Tableau, Excel).
    - Ease of use for end-users and analysts.
    - Consistency across integrated CRM and ERP data sources.

DESIGN PRINCIPLES:
    - Master Data Management: Merging CRM and ERP sources for a 'Single View of Truth'.
    - Performance: Filtering out historical product data in dim_products.
    - Security: Masking raw IDs where surrogate keys (ROW_NUMBER) are provided.
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1. Create Dimension: gold.dim_customers
-------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate Key for reporting
    ci.cst_id               AS customer_id, 
    ci.cst_key              AS customer_number, 
    ci.cst_firstname        AS first_name, 
    ci.cst_lastname         AS last_name, 
    la.cntry                AS country,
    ci.cst_marital_status   AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- Priority: CRM Source (Master)
        ELSE COALESCE(ca.gen, 'n/a')               -- Fallback: ERP Source
    END AS gender,
    ca.bdate                AS birthdate,
    ci.cst_create_date      AS create_date
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN Silver.erp_loc_a101 la  ON ci.cst_key = la.cid;
GO

-------------------------------------------------------------------------------
-- 2. Create Dimension: gold.dim_products
-------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate Key
    pn.prd_id               AS product_id,
    pn.prd_key              AS product_number, 
    pn.prd_nm               AS product_name,
    pn.cat_id               AS category_id,
    pc.cat                  AS category,
    pc.subcat               AS sub_category,
    pc.maintenance,
    pn.prd_cost             AS cost,
    pn.prd_line             AS product_line, 
    pn.prd_start_dt         AS start_date
FROM Silver.crm_prd_info pn
LEFT JOIN Silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Business Rule: Only current active products included
GO

-------------------------------------------------------------------------------
-- 3. Create Fact: gold.fact_sales
-------------------------------------------------------------------------------
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num     AS order_number, 
    pr.product_key,    -- Linking to Dimension
    cu.customer_key,   -- Linking to Dimension
    sd.sls_order_dt    AS order_date,
    sd.sls_ship_dt     AS shipping_date, 
    sd.sls_due_dt      AS due_date, 
    sd.sls_sales       AS sales, 
    sd.sls_quantity    AS quantity, 
    sd.sls_price       AS price
FROM Silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;
GO
