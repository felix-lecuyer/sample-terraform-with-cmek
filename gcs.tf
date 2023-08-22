data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

# The gcs default storage account must be given access to the KMS Key.
resource "google_kms_crypto_key_iam_member" "gcs_default_sa" {
  crypto_key_id = var.kms_key_path
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  depends_on = [module.project-services]
}

resource "google_storage_bucket" "bucket" {
  name     = "sample-sovereign-bucket"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = var.kms_key_path
  }

  # Ensure the KMS crypto-key IAM binding for the service account exists prior to the
  # bucket attempting to utilise the crypto-key.
  depends_on = [google_kms_crypto_key_iam_member.gcs_default_sa, module.project-services]
}