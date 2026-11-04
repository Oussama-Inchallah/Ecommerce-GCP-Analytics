
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
from functions.ingest_api import download_dataset, upload_to_gcs


with DAG(
    "ecommerce_ingestion_dag",
    schedule="@daily",
    start_date=datetime(2026, 11, 4),
    catchup=False,
) as dag:

    download_task = PythonOperator(
        task_id="download_dataset",
        python_callable=download_dataset,
    )

    upload_task = PythonOperator(
        task_id="upload_to_gcs",
        python_callable=upload_to_gcs,
        op_kwargs={
            "local_file_path": "{{ ti.xcom_pull(task_ids='download_dataset') }}",
        },
    )

    download_task >> upload_task