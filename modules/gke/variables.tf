variable "name" {
  type        = string
  description = "Name of the cluster"
}

variable "project_id" {
  description = "Id of the project where to deploy the GKE cluster"
  type        = string
}

variable "region" {
  description = "Region where to deploy the GKE cluster. Default to Frankfurt."
  default     = "europe-west3"
  type        = string
}

variable "kms_key_path" {
  description = "The Customer Managed Encryption Key used to encrypt the boot disks of the node autoprovisioned by the cluster. This should be of the form projects/[KEY_PROJECT_ID]/locations/[LOCATION]/keyRings/[RING_NAME]/cryptoKeys/[KEY_NAME]"
  type        = string
}

variable "network_id" {
  type        = string
  description = "Network id where to deploy the cluster"
}

variable "subnetwork_id" {
  type        = string
  description = "Subnetwork id where to deploy the cluster"
}

variable "cluster_secondary_range_name" {
  type        = string
  default     = "pods"
  description = "Name of the cluster secondary ip range"
}

variable "services_secondary_range_name" {
  type        = string
  default     = "services"
  description = "Name of the cluster secondary ip range"
}