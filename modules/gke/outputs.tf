output "id" {
  value = google_container_cluster.main.id
}

output "name" {
  value = google_container_cluster.main.name
}

output "host" {
  value = "https://${google_container_cluster.main.endpoint}"
}

output "cluster_sa_email" {
  value = google_service_account.cluster.email
}