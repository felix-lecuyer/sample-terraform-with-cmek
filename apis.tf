# Enable required APIs

resource "google_project_service" "services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
   "cloudkms.googleapis.com",
  ])
  project = var.project_id
  service = each.value
}
