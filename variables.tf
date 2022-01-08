variable "PROJECT_ID" {
  type = string
}
variable "GOOGLE_CREDENTIALS" {}
locals {
  services = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "datastore.googleapis.com",
    "clouddebugger.googleapis.com",
    "cloudfunctions.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "sql-component.googleapis.com",
    "storage-component.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudapis.googleapis.com",
    "storage-api.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}
