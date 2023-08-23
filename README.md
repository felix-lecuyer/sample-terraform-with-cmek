# sample-terraform-with-cmek

Sample terraform configurations using customer managed encryption keys (CMEK).

A CMEK is needed in some configuration, for example when using external keys. It is mandatory when using [sovereign controls by partners](https://cloud.google.com/sovereign-controls-by-partners/docs/overview).

The samples show how to deploy following resources using a CMEK to encrypt customer data:
- a GKE cluster with a node-pool
- a GCS bucket
- a VPC Network

## Requirements

- a GCP Organization
- a GCP Project
- a CMEK
