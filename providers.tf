locals {
  region          = "europe-west1"
  billing_project = "cf-rice-project-app"
  project         = "cfarm-tech-${local.env}-apps"
}

provider "google" {
  user_project_override = true
  region                = local.region
  billing_project       = local.billing_project
  project               = local.project
}

provider "google-beta" {
  user_project_override = true
  region                = local.region
  billing_project       = local.billing_project
  project               = local.project
}
