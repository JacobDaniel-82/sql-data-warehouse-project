/*
===============================================================================
STORED PROCEDURE: bronze.load_bronze
===============================================================================
LAYER: Bronze (Raw Data)
PURPOSE: 
    Extracts raw data from external CSV files (CRM and ERP sources) 
    and loads it into the Bronze layer tables as-is.

LOGIC:
    - Measures duration for each table and the entire batch.
    - Uses TRUNCATE to clear tables before fresh insertion.
    - Uses BULK INSERT for high-performance data loading.

PARAMETERS:
    -None

USAGE EXAMPLE:
    EXEC bronze.load_bronze;

WARNING - CRITICAL :
    - This procedure TRUNCATES all target bronze tables.
    - Running this will PERMANENTLY WIPE existing data in the Bronze layer.
    - Ensure CSV files exist at specified 'H:\' paths before execution.
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, 
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '=========================================================================';
        PRINT 'L O A D I N G   B R O N Z E   L A Y E R';
        PRINT '=========================================================================';

        -------------------------------------------------------------------------------
        -- 1. Loading CRM Source Tables
        -------------------------------------------------------------------------------
        PRINT '-------------------------------------------------------------------------';
        PRINT '>> Loading CRM Source Data';
        PRINT '-------------------------------------------------------------------------';

        -- Table: bronze.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '   - Inserting:  bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_crm\cust_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';

        -- Table: bronze.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '   - Inserting:  bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_crm\prd_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';

        -- Table: bronze.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '   - Inserting:  bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_crm\sales_details.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';


        -------------------------------------------------------------------------------
        -- 2. Loading ERP Source Tables
        -------------------------------------------------------------------------------
        PRINT '-------------------------------------------------------------------------';
        PRINT '>> Loading ERP Source Data';
        PRINT '-------------------------------------------------------------------------';

        -- Table: bronze.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '   - Inserting:  bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_erp\LOC_A101.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';

        -- Table: bronze.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '   - Inserting:  bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_erp\CUST_AZ12.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';

        -- Table: bronze.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '   - Truncating: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '   - Inserting:  bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'H:\SQL\pract\Data Warehouse Project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        SET @end_time = GETDATE();
        PRINT '   - Duration:   ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------------------------------';

        -------------------------------------------------------------------------------
        -- Batch Completion Summary
        -------------------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '=========================================================================';
        PRINT 'B R O N Z E   L A Y E R   L O A D   C O M P L E T E D';
        PRINT ' - Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=========================================================================';

    END TRY
    BEGIN CATCH 
        PRINT '=========================================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State:   ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=========================================================================';
    END CATCH
END;
