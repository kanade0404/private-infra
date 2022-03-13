terraform {
  backend "gcs" {
    bucket = "terraform-state-88643b14-24ae-483f-935d-082bb575064a"
    prefix = "terraform/state"
  }
}
