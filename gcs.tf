locals {
  tfstate_buckets = [
    "zaim"
  ]
}

resource "google_storage_bucket" "tfstate" {
  location                    = local.location
  name                        = "tfstate-${var.PROJECT_ID}-${random_uuid.uuid.id}"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "tfstate_directory" {
  for_each = toset(local.tfstate_buckets)
  bucket   = google_storage_bucket.tfstate.id
  name     = each.value
  source   = "/${each.value}"
  depends_on = [
    google_storage_bucket.tfstate
  ]
}
