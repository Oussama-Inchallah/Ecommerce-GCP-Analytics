variable "project_id" {
  type        = string
  description = "Google Cloud project ID."
}

variable "region" {
  type        = string
  description = "Primary Google Cloud region."
  default     = "europe-west9"
}

variable "zone" {
  type        = string
  description = "Compute zone used by Composer."
  default     = "europe-west9-b"
}

variable "landing_bucket_name" {
  type        = string
  description = "Globally unique GCS bucket name for raw landing files."
}

variable "composer_name" {
  type    = string
  default = "ecommerce-composer"
}

variable "composer_image_version" {
  type        = string
  description = "Composer image version, for example composer-3-airflow-2.10.5."
}

variable "composer_network" {
  type        = string
  description = "Existing VPC network self-link or name for Composer."
  default     = "default"
}

variable "composer_subnetwork" {
  type        = string
  description = "Existing regional subnetwork self-link or name for Composer."
}

variable "dbt_image_tag" {
  type    = string
  default = "latest"
}

variable "kaggle_api_token" {
  type        = string
  sensitive   = true
  description = "Kaggle API token injected into Composer as an environment variable."
}