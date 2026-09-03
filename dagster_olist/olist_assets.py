import os
import snowflake.connector
from dagster import asset, get_dagster_logger
from dotenv import load_dotenv
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization

# Load environment variables (credentials, paths) from the local .env file
load_dotenv()

'''
This Dagster asset automates raw data ingestion into Snowflake using RSA key-pair authentication. 
It loops through 9 local Olist CSV files, uploads them to Snowflake's internal table stages (PUT), 
and bulk-loads the data into raw destination tables (COPY INTO).
'''

# Mapping dictionary: Maps local CSV file names to their corresponding target Snowflake raw table names
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

def get_private_key(key_path):
    """
    Reads an encrypted or unencrypted PEM private key from disk and converts 
    it into PKCS#8 DER-encoded bytes required by the Snowflake Python Connector.
    """
    with open(key_path, "rb") as key_file:
        p_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None,  # Set to passphrase string if private key is encrypted
            backend=default_backend()
        )
    
    # Export key as unencrypted PKCS#8 formatted DER bytes
    pkb = p_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    return pkb

@asset  # Registers this Python function as a Dagster Software-Defined Asset
def load_raw_olist_to_snowflake():
    """Uploads local Olist CSVs to Snowflake internal stages and copies them into raw tables."""
    
    # Instantiate Dagster logger to print structured execution logs in Dagster UI
    logger = get_dagster_logger()
    
    # Path where local raw CSV files reside
    data_dir = '../data_olist'      # use relative path
    
    # 1. Fetch private key path from environment and convert key to DER bytes
    key_path = os.getenv('SNOWFLAKE_PRIVATE_KEY_PATH')
    private_key_bytes = get_private_key(key_path)
    
    # 2. Establish connection to Snowflake using RSA key-pair authentication
    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        private_key=private_key_bytes,
        role=os.getenv('SNOWFLAKE_ROLE'),
        warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
        database=os.getenv('SNOWFLAKE_DATABASE'),
        schema=os.getenv('SNOWFLAKE_SCHEMA')
    )
    
    cursor = conn.cursor()
    
    try:
        # Iterate over each file-to-table mapping pair
        for filename, table_name in FILE_TO_TABLE_MAP.items():
            file_path = os.path.join(data_dir, filename)
            
            # Skip file processing if CSV is missing from directory
            if not os.path.exists(file_path):
                logger.warning(f"File not found, skipping: {file_path}")
                continue
                
            logger.info(f"Processing {filename} -> {table_name}")
            
            # PUT command: Staging step
            # Uploads and auto-compresses local CSV file into table's internal stage (@%table_name)
            put_query = f"PUT 'file://{file_path}' @%{table_name} AUTO_COMPRESS=TRUE OVERWRITE=TRUE;"
            cursor.execute(put_query)
            
            # COPY INTO command: Ingestion step
            # Loads staged CSV contents into destination table using pre-configured file format.
            # PURGE = TRUE automatically deletes staged file once ingestion completes.
            copy_query = f"""
            COPY INTO {table_name}
            FROM @%{table_name}
            FILE_FORMAT = (FORMAT_NAME = 'olist_csv_format')
            MATCH_BY_COLUMN_NAME = NONE
            PURGE = TRUE;
            """
            cursor.execute(copy_query)
            
            logger.info(f"Successfully loaded {table_name}")
            
    finally:
        # Guarantee database cursor and connection close even if errors occur
        cursor.close()
        conn.close()
        
    return "All raw Olist data loaded successfully."