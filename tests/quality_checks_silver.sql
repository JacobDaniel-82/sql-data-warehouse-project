/*
===============================================================================
QUALITY CHECK SCRIPT: Bronze vs. Silver Layer
===============================================================================
PURPOSE:
    This script contains two phases of quality checks:
    1. Discovery (Bronze): Identifying data quality issues (nulls, duplicates, 
       formatting, logic errors) before transformation.
    2. Verification (Silver): Validating that the 'Silver.load_silver' procedure 
       successfully cleansed and transformed the data.

SCOPE:
    Covers CRM and ERP sources for Customers, Products, Sales, and Locations.
===============================================================================
*/

-------------------------------------------------------------------------------
-- PHASE 1: DISCOVERY (Checking Bronze Layer for Issues)
-------------------------------------------------------------------------------

PRINT '--- DISCOVERY: Checking Bronze Layer for Quality Issues ---';

-- 1. Check for Duplicate or Null Primary Keys (CRM Customers)
-- Expected: Empty result
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Check for Unwanted Spaces in CRM Customers
-- Logic: If results appear, these fields require TRIM()
SELECT cst_firstname FROM bronze.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname);
SELECT cst_lastname  FROM bronze.crm_cust_info WHERE cst_lastname  != TRIM(cst_lastname);

-- 3. Check Data Standardization (CRM Customers)
-- Logic: Observe inconsistent values like 'F', 'Female', 'M', 'Male'
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;

-- 4. Check for Invalid Logic (CRM Products)
-- Logic: Ensure end dates are not before start dates
SELECT * FROM bronze.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-- 5. Check for Null/Negative Costs (CRM Products)
SELECT prd_cost FROM bronze.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 6. Check Date Validity (CRM Sales)
-- Logic: Identify dates outside reasonable ranges or malformed strings
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 OR sls_order_dt > 20500101 OR sls_order_dt < 19000101;

-- 7. Check Data Consistency (CRM Sales)
-- Logic: Sales should equal Quantity * Price. ABS() used to check for negative price issues.
SELECT sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * ABS(sls_price) 
   OR sls_sales IS NULL OR sls_sales <= 0;

-- 8. Check for Invalid Birthdates (ERP Customers)
-- Logic: Dates in the future or unrealistic past
SELECT DISTINCT bdate FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- 9. Check Data Standardization (ERP Locations)
-- Logic: Check for abbreviations like 'DE', 'USA'
SELECT DISTINCT cntry FROM bronze.erp_loc_a101;


-------------------------------------------------------------------------------
-- PHASE 2: VERIFICATION (Validating Silver Layer Cleansing)
-------------------------------------------------------------------------------

PRINT '--- VERIFICATION: Validating Silver Layer (Post-Transformation) ---';

-- 1. Verify: Deduplication & No Nulls (Silver Customers)
-- Result should be empty
SELECT cst_id, COUNT(*)
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Verify: All Strings are Trimmed (Silver Customers)
-- Result should be empty
SELECT cst_firstname FROM Silver.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname);

-- 3. Verify: Gender & Marital Status Standardized (Silver Customers)
-- Expected: 'Male', 'Female', 'Single', 'Married', 'n/a'
SELECT DISTINCT cst_gndr FROM Silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM Silver.crm_cust_info;

-- 4. Verify: Dates are Correctly Cast & Logical (Silver Products)
-- Expected: prd_end_dt is handled by LEAD() logic and >= prd_start_dt
SELECT * FROM Silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-- 5. Verify: Sales Calculation Integrity (Silver Sales)
-- Logic: Verify that sls_sales = sls_quantity * sls_price
-- Expected: Empty result (all corrections applied in procedure)
SELECT * FROM Silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity OR sls_sales <= 0;

-- 6. Verify: ERP Customer Birthdates & Gender Standardized
-- Expected: No future dates, consistent gender labels
SELECT DISTINCT bdate FROM Silver.erp_cust_az12 WHERE bdate > GETDATE();
SELECT DISTINCT gen FROM Silver.erp_cust_az12;

-- 7. Verify: ERP Location Names Standardized
-- Expected: Full country names (e.g., 'United States' instead of 'US')
SELECT DISTINCT cntry FROM Silver.erp_loc_a101;
