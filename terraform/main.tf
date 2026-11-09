locals {
  required_services = toset([
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudbuild.googleapis.com",
    "composer.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ])

  dbt_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.dbt.repository_id}/dbt:${var.dbt_image_tag}"
  cloudbuild_compute_service_account = "${data.google_project.current.number}-compute@developer.gserviceaccount.com"

  composer_files = merge(
    {
      for file in fileset("${path.module}/../dags", "**") :
      "dags/${file}" => "${path.module}/../dags/${file}"
    },
    {
      for file in fileset("${path.module}/../functions", "**") :
      "dags/functions/${file}" => "${path.module}/../functions/${file}"
    }
  )
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_project_service" "required" {
  for_each           = local.required_services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "composer" {
  account_id   = "ecommerce-composer"
  display_name = "Ecommerce Composer service account"
  project      = var.project_id
}

resource "google_service_account" "dbt" {
  account_id   = "ecommerce-dbt"
  display_name = "Ecommerce dbt Cloud Run service account"
  project      = var.project_id
}

resource "google_project_iam_member" "composer_roles" {
  for_each = toset([
    "roles/composer.Worker",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/storage.objectAdmin",
    "roles/run.invoker",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_project_iam_member" "dbt_roles" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataViewer",
    "roles/bigquery.dataEditor",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.cloudbuild_compute_service_account}"
}

resource "google_storage_bucket_iam_member" "cloudbuild_source_reader" {
  bucket = "${var.project_id}_cloudbuild"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.cloudbuild_compute_service_account}"
}

resource "google_service_account_iam_member" "composer_can_run_dbt" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_storage_bucket" "landing" {
  name                        = var.landing_bucket_name
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  lifecycle_rule {
    condition {
      age            = 30
      matches_prefix = ["processed/"]
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_storage_bucket_iam_member" "composer_landing" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_bigquery_dataset" "raw" {
  project    = var.project_id
  dataset_id = "raw_ecommerce"
  location   = var.region
}

resource "google_bigquery_dataset" "dbt" {
  project    = var.project_id
  dataset_id = "dbt_dev"
  location   = var.region
}

resource "google_artifact_registry_repository" "dbt" {
  project       = var.project_id
  location      = var.region
  repository_id = "ecommerce-dbt"
  description   = "Docker images for the ecommerce dbt job"
  format        = "DOCKER"
}

resource "google_cloud_run_v2_job" "dbt" {
  name     = "dbt-build"
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = google_service_account.dbt.email
      max_retries     = 0

      containers {
        image = local.dbt_image

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "REGION"
          value = var.region
        }
      }
    }
  }

  depends_on = [
    google_project_service.required,
    google_artifact_registry_repository.dbt,
  ]
}

resource "google_composer_environment" "main" {
  name    = var.composer_name
  project = var.project_id
  region  = var.region

  config {
    software_config {
      image_version = var.composer_image_version

      pypi_packages = {
        "kagglehub"     = "==1.0.3"
        "python-dotenv" = "==1.2.4"
      }

      env_variables = {
        PROJECT_ID        = var.project_id
        REGION            = var.region
        E_GCS_BUCKET        = google_storage_bucket.landing.name
        GCS_OBJECT_PREFIX = "raw"
        DBT_CLOUD_RUN_JOB = google_cloud_run_v2_job.dbt.name
        KAGGLE_API_TOKEN  = var.kaggle_api_token
      }
    }

    node_config {
      zone            = var.zone
      service_account = google_service_account.composer.email
      network         = var.composer_network
      subnetwork      = var.composer_subnetwork
    }
  }

  depends_on = [
    google_project_service.required,
    google_service_account.composer,
  ]
}

resource "google_storage_bucket_object" "composer_dags" {
  for_each = local.composer_files
  name     = each.key
  bucket   = split("/", trimprefix(google_composer_environment.main.config[0].dag_gcs_prefix, "gs://"))[0]
  source   = each.value
}