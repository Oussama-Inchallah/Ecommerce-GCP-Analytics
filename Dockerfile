FROM apache/airflow:2.9.3

USER airflow

RUN pip install --no-cache-dir \
    google-cloud-storage \
    kagglehub[pandas-datasets] \
    python-dotenv
