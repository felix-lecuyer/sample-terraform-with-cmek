# Enable required APIs
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 12.0"

  project_id = var.project_id

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
  ]
  disable_services_on_destroy = false
}

data "google_project" "project" {
  project_id = var.project_id
  depends_on = [module.project-services]
}

# We create the service account and provide general iam roles

resource "google_service_account" "cluster" {
  account_id   = var.name
  display_name = "Service Account used by GKE cluster: '${var.name}'."
  depends_on   = [module.project-services]
}

resource "google_project_iam_member" "cluster_log_writer" {
  project    = var.project_id
  role       = "roles/logging.logWriter"
  member     = "serviceAccount:${google_service_account.cluster.email}"
  depends_on = [module.project-services]
}

resource "google_project_iam_member" "cluster_metric_writer" {
  project    = var.project_id
  role       = "roles/monitoring.metricWriter"
  member     = "serviceAccount:${google_service_account.cluster.email}"
  depends_on = [module.project-services]
}

resource "google_project_iam_member" "cluster_monitoring_viewer" {
  project    = var.project_id
  role       = "roles/monitoring.viewer"
  member     = "serviceAccount:${google_service_account.cluster.email}"
  depends_on = [module.project-services]
}

resource "google_project_iam_member" "cluster_metadata_writer" {
  project    = var.project_id
  role       = "roles/stackdriver.resourceMetadata.writer"
  member     = "serviceAccount:${google_service_account.cluster.email}"
  depends_on = [module.project-services]
}


# We need to provide access to the KMS Key to the previously created service account, but also to the default service accounts.

resource "google_kms_crypto_key_iam_member" "gke_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.cluster.email}"
  depends_on    = [module.project-services]
}

resource "google_kms_crypto_key_iam_member" "compute_engine_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
  depends_on    = [module.project-services]
}

resource "google_kms_crypto_key_iam_member" "container_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  depends_on    = [module.project-services]
}

# This is a sample GKE Cluster, with one node-pool, and cluster auto-scaling activated.
resource "google_container_cluster" "main" {
  name       = var.name
  location   = var.region
  project    = var.project_id
  network    = var.network_id
  subnetwork = var.subnetwork_id

  database_encryption {
    key_name = var.kms_key_path
    state    = "ENCRYPTED"
  }

  remove_default_node_pool = true
  initial_node_count       = 1
  node_config {
    machine_type      = "e2-medium"
    boot_disk_kms_key = var.kms_key_path
    service_account   = google_service_account.cluster.email
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
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
      service_account   = google_service_account.cluster.email

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

resource "google_container_node_pool" "main" {
  name     = "main"
  location = var.region
  cluster  = google_container_cluster.main.name
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
    service_account   = google_service_account.cluster.email
  }
}