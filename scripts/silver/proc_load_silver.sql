/*
===============================================================================
STORED PROCEDURE: Silver.load_silver
===============================================================================
LAYER: Silver (Curated Data)
PURPOSE: 
    Cleanses, deduplicates, standardizes, and transforms Bronze layer raw data 
    into Silver layer tables with consistent formats and business rules applied.

LOGIC:
    - Measures duration for each table and the entire batch.
    - Uses TRUNCATE to clear Silver tables before fresh transformation.
    - Applies data cleansing (TRIM, CASE), deduplication (ROW_NUMBER), 
      and standardization transformations.

WARNING - CRITICAL :
    - This procedure TRUNCATES all target Silver tables.
    - Running this will PERMANENTLY WIPE existing data in the Silver layer.
===============================================================================
*/

CREATE OR ALTER PROCEDURE Silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, 
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '=========================================================================';
        PRINT 'L O A D I N G   S I L V E R   L A Y E R';
        PRINT '=========================================================================';

        -------------------------------------------------------------------------------
        -- 1. Loading CRM Silver Tables
        -------------------------------------------------------------------------------
        PRINT '-------------------------------------------------------------------------';
        PRINT '>> Loading CRM Curated Data';
        PRINT '-------------------------------------------------------------------------';

        -- Table: Silver.crm_cust_info
        -- Logic: Deduplicate based on cst_id and keep the most recent record.
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.crm_cust_info';
        TRUNCATE TABLE Silver.crm_cust_info;

        PRINT '   - Inserting:  Silver.crm_cust_info';
        INSERT INTO Silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname, 
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE 
                WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Single'
                WHEN TRIM(UPPER(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE 
                WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
                WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM (
            SELECT *,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Table: Silver.crm_prd_info
        -- Logic: Split prd_key into category and key; handle SCD-like start/end dates.
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.crm_prd_info';
        TRUNCATE TABLE Silver.crm_prd_info;

        PRINT '   - Inserting:  Silver.crm_prd_info';
        INSERT INTO Silver.crm_prd_info(
            prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
            SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
            prd_nm,
            ISNULL(prd_cost,0) as prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END as prd_line,
            CAST(prd_start_dt AS DATE),
            CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Table: Silver.crm_sales_details
        -- Logic: Convert INT dates to DATE objects and recalculate invalid sales figures.
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.crm_sales_details';
        TRUNCATE TABLE Silver.crm_sales_details;

        PRINT '   - Inserting:  Silver.crm_sales_details';
        INSERT INTO Silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, 
            sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
        )   
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END,
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END,
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------------------------------------------------
        -- 2. Loading ERP Silver Tables
        -------------------------------------------------------------------------------
        PRINT '-------------------------------------------------------------------------';
        PRINT '>> Loading ERP Curated Data';
        PRINT '-------------------------------------------------------------------------';

        -- Table: Silver.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.erp_cust_az12';
        TRUNCATE TABLE Silver.erp_cust_az12;

        PRINT '   - Inserting:  Silver.erp_cust_az12';
        INSERT INTO Silver.erp_cust_az12(cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Table: Silver.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.erp_loc_a101';
        TRUNCATE TABLE Silver.erp_loc_a101;

        PRINT '   - Inserting:  Silver.erp_loc_a101';
        INSERT INTO Silver.erp_loc_a101(cid, cntry)
        SELECT 
            REPLACE(cid,'-','') cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Table: Silver.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '   - Truncating: Silver.erp_px_cat_g1v2';
        TRUNCATE TABLE Silver.erp_px_cat_g1v2;

        PRINT '   - Inserting:  Silver.erp_px_cat_g1v2';
        INSERT INTO Silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -------------------------------------------------------------------------------
        -- Batch Completion Summary
        -------------------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '=========================================================================';
        PRINT 'S I L V E R   L A Y E R   L O A D   C O M P L E T E D';
        PRINT ' - Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================================================';

    END TRY
    BEGIN CATCH 
        PRINT '=========================================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State:   ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=========================================================================';
    END CATCH
END;
