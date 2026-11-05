from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.sensors.gcs import (
    GCSObjectsWithPrefixExistenceSensor,
)

from functions.load_Bq import (
    find_pending_objects,
    load_amazon_sales,
    move_to_processed,
)


GCS_BUCKET = os.environ["GCS_BUCKET"]
GCS_OBJECT_PREFIX = os.getenv("GCS_OBJECT_PREFIX", "raw").strip("/")


with DAG(
    "ecommerce_loading_dag",
    schedule="@daily",
    start_date=datetime(2026, 11, 5),
    catchup=False,
    render_template_as_native_obj=True,
) as dag:
    wait_for_file = GCSObjectsWithPrefixExistenceSensor(
        task_id="wait_for_file",
        bucket=GCS_BUCKET,
        prefix=f"{GCS_OBJECT_PREFIX}/",
        google_cloud_conn_id="google_cloud_default",
        poke_interval=1800,
        timeout=3600,
        mode="reschedule",
    )

    find_files = PythonOperator(
        task_id="find_pending_files",
        python_callable=find_pending_objects,
    )

    load_to_bq = PythonOperator(
        task_id="load_to_bq",
        python_callable=load_amazon_sales,
        op_kwargs={
            "object_names": "{{ ti.xcom_pull(task_ids='find_pending_files') }}",
        },
    )

    move_file = PythonOperator(
        task_id="move_to_processed",
        python_callable=move_to_processed,
        op_kwargs={
            "object_names": "{{ ti.xcom_pull(task_ids='find_pending_files') }}",
        },
    )

    wait_for_file >> find_files >> load_to_bq >> move_file
