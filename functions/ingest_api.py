import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import storage
import kagglehub
from kagglehub import KaggleDatasetAdapter


LOGGER = logging.getLogger(__name__)
PROJECT_PATH = Path(__file__).resolve().parents[1]
DATA_PATH = PROJECT_PATH / "data"
DEFAULT_DATASET = "rohiteng/amazon-sales-dataset"
DEFAULT_FILE = "Amazon.csv"
DEFAULT_OBJECT_PREFIX = "raw"

def _required_setting(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"Missing required environment variable: {name}")
    return value

def download_dataset() -> str:
    dataset = os.getenv("KAGGLE_DATASET", DEFAULT_DATASET)
    file_name = os.getenv("KAGGLE_FILE", DEFAULT_FILE)
    DATA_PATH.mkdir(parents=True, exist_ok=True)
    local_file_path = DATA_PATH / file_name

    LOGGER.info("Loading %s from Kaggle", file_name)
    dataframe = kagglehub.dataset_load(
        KaggleDatasetAdapter.PANDAS,
        dataset,
        file_name,
    )
    if dataframe is None:
        raise RuntimeError(f"Kaggle returned no data for {dataset}/{file_name}")

    dataframe.to_csv(local_file_path, index=False)
    LOGGER.info("Saved %s rows to %s", len(dataframe), local_file_path) 
    return str(local_file_path)

def upload_to_gcs(local_file_path: str):
    local_file_path = Path(local_file_path)
    bucket_name = _required_setting("GCS_BUCKET")
    project_id = os.getenv("PROJECT_ID") or os.getenv("GOOGLE_CLOUD_PROJECT")
    object_prefix = os.getenv("GCS_OBJECT_PREFIX", DEFAULT_OBJECT_PREFIX).strip("/")
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    object_name = f"{object_prefix}/{run_timestamp}_{local_file_path.name}"

    client = storage.Client(project=project_id)
    blob = client.bucket(bucket_name).blob(object_name)
    blob.upload_from_filename(local_file_path, content_type="text/csv")
    LOGGER.info("Uploaded gs://%s/%s", bucket_name, object_name)
    return f"gs://{bucket_name}/{object_name}"
