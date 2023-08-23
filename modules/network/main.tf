# Enable required APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 12.0"

  project_id = var.project_id

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
  ]
  disable_services_on_destroy = false
}


resource "google_compute_network" "network" {
  name                    = var.name
  auto_create_subnetworks = false
}

locals {
  # We precompute the subnetwork names to have unique identifiers in terraform state
  subnets_map = { for s in var.subnetworks : "${var.name}-${s.name_affix}-${s.region}" => s }
  # Let's collect all regions we are using
  regions = toset([for s in var.subnetworks : s.region])
}

# Let's create the specified subnetworks
resource "google_compute_subnetwork" "subnetworks" {
  for_each = local.subnets_map
  name     = each.key
  network  = google_compute_network.network.id
  region   = each.value.region

  private_ip_google_access   = true
  private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"
  ip_cidr_range              = each.value.ip_cidr_range
  purpose                    = "PRIVATE"

  secondary_ip_range = each.value.secondary_ip_range
}

# And for each region we create a router and make sure NAT is set up
resource "google_compute_router" "router" {
  for_each = local.regions
  name     = "${var.name}-${each.value}"
  network  = google_compute_network.network.id
  region   = each.value
}

resource "google_compute_router_nat" "router_nat" {
  for_each = local.regions
  name     = "${var.name}-${each.value}"
  router   = google_compute_router.router[each.key].name
  region   = each.value

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}