import logging
import os
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery, storage


load_dotenv()
LOGGER = logging.getLogger(__name__)
PROJECT_ID = os.getenv("PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT")
DATASET = "raw_ecommerce"
TABLE = "amazon_sales"
BUCKET = os.getenv("GCS_BUCKET")
RAW_PREFIX = os.getenv("GCS_OBJECT_PREFIX", "raw").strip("/")


def _settings() -> tuple[str, str]:
    if not PROJECT_ID:
        raise ValueError("Missing PROJECT_ID or GOOGLE_CLOUD_PROJECT")
    if not BUCKET:
        raise ValueError("Missing GCS_BUCKET")
    return PROJECT_ID, BUCKET


def find_pending_object() -> str:
    _, bucket_name = _settings()
    blobs = storage.Client(project=PROJECT_ID).list_blobs(
        bucket_name,
        prefix=f"{RAW_PREFIX}/",
    )
    pending = [blob for blob in blobs if not blob.name.endswith("/")]
    if not pending:
        raise FileNotFoundError(f"No files found under gs://{bucket_name}/{RAW_PREFIX}/")
    pending.sort(key=lambda blob: blob.time_created)
    return pending[0].name


def load_amazon_sales(object_name: str) -> dict[str, str | int]:
    project_id, bucket_name = _settings()
    object_name = Path(object_name).as_posix().lstrip("/")
    uri = f"gs://{bucket_name}/{object_name}"
    table_ref = f"{project_id}.{DATASET}.{TABLE}"
    client = bigquery.Client(project=project_id)

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=[
            bigquery.SchemaField("order_id", "STRING"),
            bigquery.SchemaField("order_date", "DATE"),
            bigquery.SchemaField("customer_id", "STRING"),
            bigquery.SchemaField("customer_name", "STRING"),
            bigquery.SchemaField("product_id", "STRING"),
            bigquery.SchemaField("product_name", "STRING"),
            bigquery.SchemaField("category", "STRING"),
            bigquery.SchemaField("brand", "STRING"),
            bigquery.SchemaField("quantity", "INTEGER"),
            bigquery.SchemaField("unit_price", "FLOAT"),
            bigquery.SchemaField("discount", "FLOAT"),
            bigquery.SchemaField("tax", "FLOAT"),
            bigquery.SchemaField("shipping_cost", "FLOAT"),
            bigquery.SchemaField("total_amount", "FLOAT"),
            bigquery.SchemaField("payment_method", "STRING"),
            bigquery.SchemaField("order_status", "STRING"),
            bigquery.SchemaField("city", "STRING"),
            bigquery.SchemaField("state", "STRING"),
            bigquery.SchemaField("country", "STRING"),
            bigquery.SchemaField("seller_id", "STRING"),
        ],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    LOGGER.info("Loading %s into %s", uri, table_ref)
    load_job = client.load_table_from_uri(uri, table_ref, job_config=job_config)
    load_job.result()
    return {"rows_loaded": load_job.output_rows, "object_name": object_name}


def move_to_processed(object_name: str) -> str:
    _, bucket_name = _settings()
    source_name = Path(object_name).as_posix().lstrip("/")
    processed_name = f"processed/{Path(source_name).name}"
    bucket = storage.Client(project=PROJECT_ID).bucket(bucket_name)
    bucket.copy_blob(bucket.blob(source_name), bucket, processed_name)
    bucket.delete_blob(source_name)
    LOGGER.info("Moved gs://%s/%s to gs://%s/%s", bucket_name, source_name, bucket_name, processed_name)
    return processed_name
