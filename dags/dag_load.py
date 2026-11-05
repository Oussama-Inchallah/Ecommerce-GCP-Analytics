from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.sensors.gcs import (
    GCSObjectsWithPrefixExistenceSensor,
)

from functions.load_Bq import find_pending_object, load_amazon_sales, move_to_processed


GCS_BUCKET = os.environ["GCS_BUCKET"]
GCS_OBJECT_PREFIX = os.getenv("GCS_OBJECT_PREFIX", "raw").strip("/")


with DAG(
    "ecommerce_loading_dag",
    schedule="@daily",
    start_date=datetime(2026, 11, 5),
    catchup=False,
) as dag:
    wait_for_file = GCSObjectsWithPrefixExistenceSensor(
        task_id="wait_for_file",
        bucket=GCS_BUCKET,
        prefix=f"{GCS_OBJECT_PREFIX}/",
        google_cloud_conn_id="google_cloud_default",
        poke_interval=120,
        timeout=86400,
        mode="reschedule",
    )

    find_file = PythonOperator(
        task_id="find_pending_file",
        python_callable=find_pending_object,
    )

    load_to_bq = PythonOperator(
        task_id="load_to_bq",
        python_callable=load_amazon_sales,
        op_kwargs={
            "object_name": "{{ ti.xcom_pull(task_ids='find_pending_file') }}",
        },
    )

    move_file = PythonOperator(
        task_id="move_to_processed",
        python_callable=move_to_processed,
        op_kwargs={
            "object_name": "{{ ti.xcom_pull(task_ids='find_pending_file') }}",
        },
    )

    wait_for_file >> find_file >> load_to_bq >> move_file
