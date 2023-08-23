variable "project_id" {
  description = "Id of the project where to deploy the resources"
  type        = string
}

variable "region" {
  description = "Region where to deploy the GKE cluster. Default to Frankfurt."
  default     = "europe-west3"
  type        = string
}

variable "kms_key_path" {
  description = "The Customer Managed Encryption Key used to encrypt the data. This should be of the form projects/[KEY_PROJECT_ID]/locations/[LOCATION]/keyRings/[RING_NAME]/cryptoKeys/[KEY_NAME]"
  type        = string
}