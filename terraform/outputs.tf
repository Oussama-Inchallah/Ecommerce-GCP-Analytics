output "landing_bucket" {
  value = google_storage_bucket.landing.name
}

output "composer_name" {
  value = google_composer_environment.main.name
}

output "composer_service_account" {
  value = google_service_account.composer.email
}

output "dbt_service_account" {
  value = google_service_account.dbt.email
}

output "dbt_cloud_run_job" {
  value = google_cloud_run_v2_job.dbt.name
}

output "dbt_image" {
  value = local.dbt_image
}