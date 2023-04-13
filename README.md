# sample-terraform-with-cmek

Sample terraform configurations using customer managed encryption keys (CMEK).

A CMEK is needed in some configuration, for example when using external keys. It is mandatory when using [sovereign controls by partners](https://cloud.google.com/sovereign-controls-by-partners/docs/overview).

The samples show how to deploy a GCS Bucket and a Kubernetes cluster using a CMEK. 

## Requirements

- a GCP Organization
- a GCP Project with Compute Engine and Kubernetes API enabled
