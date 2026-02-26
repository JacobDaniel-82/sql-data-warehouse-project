/*
===============================================================================
QUALITY CHECK SCRIPT: Gold Layer (Final Model)
===============================================================================
PURPOSE:
    Validates the integrity, uniqueness, and consistency of the final 
    reporting views in the Gold Layer.

SCOPE:
    - Business Logic Validation: CRM vs. ERP data merging.
    - Uniqueness: Checking surrogate keys.
    - Referential Integrity: Ensuring Fact-to-Dimension joins are healthy.
===============================================================================
*/

PRINT '--- QUALITY CHECK: Gold Layer Model ---';

-------------------------------------------------------------------------------
-- 1. Logic Check: CRM vs. ERP Gender Integration (dim_customers)
-------------------------------------------------------------------------------
-- Verification: Ensure the priority logic (CRM > ERP) is working as intended.
SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen      AS erp_gender,
    dc.gender   AS final_gender
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN gold.dim_customers dc   ON ci.cst_id  = dc.customer_id
ORDER BY 1, 2;


-------------------------------------------------------------------------------
-- 2. Uniqueness Check: Surrogate Keys
-------------------------------------------------------------------------------
-- dim_customers: customer_key should be unique
PRINT '>> Checking Uniqueness of customer_key';
SELECT customer_key, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- dim_products: product_key should be unique
PRINT '>> Checking Uniqueness of product_key';
SELECT product_key, COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-------------------------------------------------------------------------------
-- 3. Data Completeness: Fact Table Foreign Keys
-------------------------------------------------------------------------------
-- Verification: Every sale must link to a valid customer and product.
-- If any rows appear here, it means we have "Orphan Sales" (Data Loss).

PRINT '>> Checking for Orphan Sales (Invalid Customer Links)';
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

PRINT '>> Checking for Orphan Sales (Invalid Product Links)';
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


-------------------------------------------------------------------------------
-- 4. Consistency: Sales Figure Totals
-------------------------------------------------------------------------------
-- Logic: Total Sales in Gold should match Total Sales in Silver exactly.
-- This ensures no records were lost or duplicated during the view joins.

SELECT 
    'Silver Layer' AS layer, SUM(sls_sales) AS total_sales FROM Silver.crm_sales_details
UNION ALL
SELECT 
    'Gold Layer'   AS layer, SUM(sales)     AS total_sales FROM gold.fact_sales;


-------------------------------------------------------------------------------
-- 5. Business Rules: dim_products
-------------------------------------------------------------------------------
-- Logic: Since Gold should only show active products, prd_end_dt must be null.
PRINT '>> Checking for historical products in Gold (Should be empty)';
SELECT * FROM gold.dim_products 
WHERE product_id IN (SELECT prd_id FROM Silver.crm_prd_info WHERE prd_end_dt IS NOT NULL);
