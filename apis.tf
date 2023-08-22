# Enable required APIs

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 12.0"

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
   "cloudkms.googleapis.com",
  ]
  disable_services_on_destroy = false
}