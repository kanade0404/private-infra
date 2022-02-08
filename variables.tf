variable "PROJECT_ID" {
  type = string
}
variable "GOOGLE_CREDENTIALS" {}
locals {
  services = [
    // BigQuery API
    "bigquery.googleapis.com",
    // BigQuery Storage API
    "bigquerystorage.googleapis.com",
    // Cloud Datastore API
    "datastore.googleapis.com",
    // Cloud Debugger API
    "clouddebugger.googleapis.com",
    // Cloud Functions API
    "cloudfunctions.googleapis.com",
    // Cloud Logging API
    "logging.googleapis.com",
    // Cloud Monitoring API
    "monitoring.googleapis.com",
    // Cloud Pub/Sub API
    "pubsub.googleapis.com",
    // Cloud SQL
    "sql-component.googleapis.com",
    // Cloud Storage
    "storage-component.googleapis.com",
    // Cloud Storage API
    "storage.googleapis.com",
    // Cloud Trace API
    "cloudtrace.googleapis.com",
    // Google Cloud APIs
    "cloudapis.googleapis.com",
    // Google Cloud Storage JSON API
    "storage-api.googleapis.com",
    // Service Management API
    "servicemanagement.googleapis.com",
    // Service Usage API
    "serviceusage.googleapis.com",
    // Cloud Resource Manager API
    "cloudresourcemanager.googleapis.com",
    // Cloud Build API
    "cloudbuild.googleapis.com",
    // Cloud Key Management Service (KMS) API	
    "cloudkms.googleapis.com",
    // Cloud Firestore API
    "firestore.googleapis.com",
    // App Engine Admin API
    "appengine.googleapis.com",
    // Firebase Rules API
    "firebaserules.googleapis.com",
    // IAM Service Account Credentials API
    "iamcredentials.googleapis.com"
  ]
}
