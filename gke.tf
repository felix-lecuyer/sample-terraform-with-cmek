data "google_project" "project" {
  project_id = var.project_id
  depends_on = [module.project-services]
}

resource "google_service_account" "gke_service_account" {
  account_id   = "sample-gke-sa"
  project      = var.project_id
  display_name = "Service Account"
  depends_on = [module.project-services]
}

# We need to provide access to the KMS Key to the previously created service account, but also to the default service accounts.

resource "google_kms_crypto_key_iam_member" "gke_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.gke_service_account.email}"
  depends_on = [module.project-services]
}

resource "google_kms_crypto_key_iam_member" "compute_engine_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
  depends_on = [module.project-services]
}

resource "google_kms_crypto_key_iam_member" "container_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  depends_on = [module.project-services]
}

# Creating a sample VPC for the kubernetes cluster

module "gcp_network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 4.0.1"

  project_id   = var.project_id
  network_name = local.network_name

  subnets = [
    {
      subnet_name   = local.subnet_name
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
    {
      subnet_name   = local.master_auth_subnetwork
      subnet_ip     = "10.60.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
  depends_on = [module.project-services]
}

locals {
  cluster_name           = "sample-gke"
  network_name           = "sample-gke-network"
  subnet_name            = "sample-gke-subnet"
  master_auth_subnetwork = "sample-gke-master-subnet"
  pods_range_name        = "ip-range-pods-sample-gke"
  svc_range_name         = "ip-range-svc-sample-gke"
  subnet_names           = [for subnet_self_link in module.gcp_network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
}

# This is a sample GKE Cluster, with one node-pool, and cluster auto-scaling activated.
resource "google_container_cluster" "sample_gke_cluster" {
  name       = local.cluster_name
  location   = var.region
  project    = var.project_id
  network    = module.gcp_network.network_name
  subnetwork = local.subnet_names[index(module.gcp_network.subnets_names, local.subnet_name)]

  database_encryption {
    key_name = var.kms_key_path
    state    = "ENCRYPTED"
  }

  remove_default_node_pool = true
  initial_node_count       = 1
  node_config {

    machine_type      = "e2-medium"
    boot_disk_kms_key = var.kms_key_path
    service_account   = google_service_account.gke_service_account.email
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.svc_range_name
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 4
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = 6
    }

    auto_provisioning_defaults {
      boot_disk_kms_key = var.kms_key_path
      service_account   = google_service_account.gke_service_account.email

      management {
        auto_repair  = true
        auto_upgrade = true
      }
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gke_sa,
    google_kms_crypto_key_iam_member.compute_engine_sa,
    google_kms_crypto_key_iam_member.container_sa
  ]

}

resource "google_container_node_pool" "gke_node_pool" {
  name     = "node-pool"
  location = var.region
  cluster  = google_container_cluster.sample_gke_cluster.name
  project  = var.project_id

  autoscaling {
    min_node_count = 1
    max_node_count = 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    disk_size_gb      = 30
    machine_type      = "e2-medium"
    boot_disk_kms_key = var.kms_key_path
    service_account   = google_service_account.gke_service_account.email
  }
}
