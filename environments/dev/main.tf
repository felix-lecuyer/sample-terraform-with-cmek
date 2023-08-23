# The underlying network mainly for the cluster

locals {
  cluster_secondary_range_name  = "pods"
  services_secondary_range_name = "services"
}

module "network" {
  source     = "../../modules/network"
  project_id = var.project_id
  name       = "network-dev"
  subnetworks = [{
    name_affix    = "main" # full name will be `${name}-${name_affix}-${region}`
    ip_cidr_range = "10.10.0.0/20"
    region        = var.region
    secondary_ip_range = [{ # Use larger ranges in production!
      range_name    = local.cluster_secondary_range_name
      ip_cidr_range = "10.10.32.0/19"
      }, {
      range_name    = local.services_secondary_range_name
      ip_cidr_range = "10.10.16.0/20"
    }]
  }]
}

# Create GKE cluster in the network

module "cluster" {
  source = "../../modules/gke"

  name                   = "cluster-dev"
  project_id                = var.project_id
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["network-dev-main-${var.region}"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  cluster_secondary_range_name  = local.cluster_secondary_range_name
  services_secondary_range_name = local.services_secondary_range_name

    kms_key_path = var.kms_key_path

  depends_on = [module.network]
}

# Let's deploy the storage bucket

module "bucket" {
  source     = "../../modules/gcs"
  name       = "dev-cmek-bucket-${var.project_id}"
  project_id = var.project_id
  region     = var.region

  kms_key_path = var.kms_key_path
}