import os
import snowflake.connector
from dagster import asset, get_dagster_logger
from dotenv import load_dotenv, find_dotenv
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization

# ------------------------------------------------------------------------------
# Environment Setup
# ------------------------------------------------------------------------------
# Automatically locate and load .env from current working dir (/app) or parent
dotenv_path = find_dotenv(usecwd=True)
if not dotenv_path:
    dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".env"))

load_dotenv(dotenv_path)

# ------------------------------------------------------------------------------
# Data & Table Mappings
# ------------------------------------------------------------------------------
FILE_TO_TABLE_MAP = {
    'olist_customers_dataset.csv': 'olist_customers',
    'olist_geolocation_dataset.csv': 'olist_geolocation',
    'olist_order_items_dataset.csv': 'olist_order_items',
    'olist_order_payments_dataset.csv': 'olist_order_payments',
    'olist_order_reviews_dataset.csv': 'olist_order_reviews',
    'olist_orders_dataset.csv': 'olist_orders',
    'olist_products_dataset.csv': 'olist_products',
    'olist_sellers_dataset.csv': 'olist_sellers',
    'product_category_name_translation.csv': 'product_category_name_translation'
}


def get_private_key(key_path: str) -> bytes:
    """
    Reads a PEM private key from disk and converts it into PKCS#8 DER-encoded bytes
    required by the Snowflake Python Connector.
    """
    if not os.path.exists(key_path):
        raise FileNotFoundError(f"RSA Private Key file not found at path: {key_path}")

    with open(key_path, "rb") as key_file:
        p_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,
            backend=default_backend()
        )
    
    return p_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )


@asset
def load_raw_olist_to_snowflake():
    """
    Uploads local Olist CSVs to Snowflake internal table stages and copies 
    them into raw destination tables with full log feedback.
    """
    logger = get_dagster_logger()
    
    # 1. Resolve absolute paths inside container (/app working directory)
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    data_dir = os.path.join(base_dir, "data_olist")
    
    logger.info(f"Resolved Data Directory: {data_dir}")
    
    # 2. Resolve RSA Key path
    key_path = os.getenv('SNOWFLAKE_PRIVATE_KEY_PATH')
    if key_path and not os.path.isabs(key_path):
        key_path = os.path.abspath(os.path.join(base_dir, key_path))
        
    logger.info(f"Loading RSA Key from: {key_path}")
    private_key_bytes = get_private_key(key_path)
    
    # 3. Establish Snowflake Connection
    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        private_key=private_key_bytes,
        role=os.getenv('SNOWFLAKE_ROLE'),
        warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
        database=os.getenv('SNOWFLAKE_DATABASE'),
        schema=os.getenv('SNOWFLAKE_SCHEMA'),
        autocommit=True
    )
    
    cursor = conn.cursor()
    files_processed = 0
    
    try:
        for filename, table_name in FILE_TO_TABLE_MAP.items():
            file_path = os.path.join(data_dir, filename)
            
            # Verify file existence inside container
            if not os.path.exists(file_path):
                logger.error(f"SKIPPED: Missing file in container at {file_path}")
                continue
                
            logger.info(f"Processing {filename} -> {table_name}")
            
            # Step A: PUT file to internal table stage
            put_query = f"PUT 'file://{file_path}' @%{table_name} AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
            put_res = cursor.execute(put_query).fetchall()
            logger.info(f"PUT Status for {table_name}: {put_res}")
            
            # Step B: COPY INTO target table
            copy_query = f"""
            COPY INTO {table_name}
            FROM @%{table_name}
            FILE_FORMAT = (FORMAT_NAME = 'olist_csv_format')
            MATCH_BY_COLUMN_NAME = NONE
            PURGE = TRUE;
            """
            copy_res = cursor.execute(copy_query).fetchall()
            logger.info(f"COPY Status for {table_name}: {copy_res}")
            
            files_processed += 1

        if files_processed == 0:
            raise FileNotFoundError(f"No CSV files were processed. Check contents of {data_dir}")

    finally:
        cursor.close()
        conn.close()
        
    return f"Successfully processed and loaded {files_processed}/{len(FILE_TO_TABLE_MAP)} tables into Snowflake."