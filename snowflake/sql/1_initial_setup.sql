-- 1. Switch to a role with sufficient privileges to create objects
USE ROLE ACCOUNTADMIN;

-- 2. Create the dedicated Warehouse specified in your profile
CREATE OR REPLACE WAREHOUSE dbt_olist_wh 
  WITH WAREHOUSE_SIZE = 'X-SMALL' 
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE 
  INITIALLY_SUSPENDED = TRUE;

-- 3. Create the new Databases ONLY if they don't already exist
CREATE DATABASE IF NOT EXISTS olist_github_raw; 
CREATE DATABASE IF NOT EXISTS olist_dev;

-- 4. Create the dedicated Role
CREATE ROLE IF NOT EXISTS dbt_olist_role;

-- 5. Grant permissions to the new Role
GRANT USAGE ON WAREHOUSE dbt_olist_wh TO ROLE dbt_olist_role;
GRANT ALL ON DATABASE olist_github_raw TO ROLE dbt_olist_role; -- FIXED: Now points to new raw database
GRANT ALL ON DATABASE olist_dev TO ROLE dbt_olist_role;

-- 6. Create schemas within your dev database for dbt to use
USE DATABASE olist_dev;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts_logistics;

-- Grant schema access to the role
GRANT ALL ON SCHEMA olist_dev.staging TO ROLE dbt_olist_role;
GRANT ALL ON SCHEMA olist_dev.marts_logistics TO ROLE dbt_olist_role;

-- 7. Assign the role to your specific user 
GRANT ROLE dbt_olist_role TO USER asoelist;

-- 8. Grant the new role to SYSADMIN so you maintain top-level control
GRANT ROLE dbt_olist_role TO ROLE SYSADMIN;