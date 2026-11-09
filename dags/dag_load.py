from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.cloud_run import (
    CloudRunExecuteJobOperator,
)
from airflow.providers.google.cloud.sensors.gcs import (
    GCSObjectsWithPrefixExistenceSensor,
)

from functions.load_Bq import (
    find_pending_objects,
    load_amazon_sales,
    move_to_processed,
)


PROJECT_ID = os.environ["PROJECT_ID"]
REGION = os.getenv("REGION", "europe-west9")
GCS_BUCKET = os.environ["GCS_BUCKET"]
GCS_OBJECT_PREFIX = os.getenv("GCS_OBJECT_PREFIX", "raw").strip("/")
DBT_CLOUD_RUN_JOB = os.environ["DBT_CLOUD_RUN_JOB"]


with DAG(
    "ecommerce_loading_dag",
    schedule="@daily",
    start_date=datetime(2026, 11, 9),
    catchup=False,
    render_template_as_native_obj=True,
) as dag:
    wait_for_file = GCSObjectsWithPrefixExistenceSensor(
        task_id="wait_for_file",
        bucket=GCS_BUCKET,
        prefix=f"{GCS_OBJECT_PREFIX}/",
        google_cloud_conn_id="google_cloud_default",
        poke_interval=120,
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

    dbt_build = CloudRunExecuteJobOperator(
        task_id="dbt_build",
        project_id=PROJECT_ID,
        region=REGION,
        job_name=DBT_CLOUD_RUN_JOB,
        gcp_conn_id="google_cloud_default",
    )

    wait_for_file >> find_files >> load_to_bq >> move_file >> dbt_build
